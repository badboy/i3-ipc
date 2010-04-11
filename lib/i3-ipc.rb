require 'socket'
require 'json'
require 'i3-ipc/runner'
require 'i3-ipc/subscription'
require 'i3-ipc/manpage'
require 'i3-ipc/version'

module I3
  class IPC
    MAGIC_STRING = "i3-ipc"
    SOCKET_PATH = File.expand_path("~/.i3/ipc.sock")

    MESSAGE_TYPE_COMMAND = 0
    MESSAGE_TYPE_GET_WORKSPACES = 1
    MESSAGE_TYPE_SUBSCRIBE = 2
    MESSAGE_TYPE_GET_OUTPUTS = 3

    MESSAGE_REPLY_COMMAND = 0
    MESSAGE_REPLY_GET_WORKSPACES = 1
    MESSAGE_REPLY_SUBSCRIBE = 2
    MESSAGE_REPLY_GET_OUTPUTS = 3

    EVENT_MASK = (1 << 31)
    EVENT_WORKSPACE = (EVENT_MASK | 0)

    class WrongMagicCode < RuntimeError; end # :nodoc:
    class WrongType < RuntimeError; end # :nodoc:

    # connects to the given i3 ipc interface
    # @param socket_path String the path to i3's socket
    # @param force_connect Boolean connects to the socket if true
    def initialize(socket_path=SOCKET_PATH, force_connect=false)
      @socket_path = socket_path
      connect if connect
    end

    # shortcut
    def self.subscribe(list, socket_path=SOCKET_PATH, &blk)
      Subscription.subscribe(list, socket_path, &blk)
    end

    # send a command to i3
    #
    # the payload is a command for i3
    # (like the commands you can bind to keys in the configuration file)
    # and will be executed directly after receiving it.
    #
    # returns { "success" => true } for now.
    # i3 does send this reply without checks
    def command(payload)
      write format(MESSAGE_TYPE_COMMAND, payload)
      handle_response MESSAGE_TYPE_COMMAND
    end

    # gets the current workspaces.
    # the reply will be the list of workspaces
    # (see the reply section of i3 docu)
    def get_workspaces
      write format(MESSAGE_TYPE_GET_WORKSPACES)
      handle_response MESSAGE_TYPE_GET_WORKSPACES
    end

    # Gets the current outputs.
    # The reply will be a JSON-encoded list
    # of outputs
    # (see the reply section of i3 docu).
    def get_outputs
      write format(MESSAGE_TYPE_GET_OUTPUTS)
      handle_response MESSAGE_TYPE_GET_OUTPUTS
    end

    # reads the reply from the socket
    # and parse the returned json into a ruby object
    #
    # throws WrongMagicCode when magic word is wrong
    # throws WrongType if returned type does not match expected
    #
    # this is a bit duplicated code
    # but I don't know a way to read the full send reply
    # without knowing its length
    def handle_response(type)
      # reads 14 bytes
      # length of "i3-ipc" + 4 bytes length + 4 bytes type
      buffer = read 14
      raise WrongMagicCode unless buffer[0, (MAGIC_STRING.length)] == MAGIC_STRING

      len, recv_type = buffer[6..-1].unpack("LL")
      raise WrongType unless recv_type == type

      answer = read len
      ::JSON.parse(answer)
    end

    # format the message
    # a typical message looks like
    #   "i3-ipc" <message length> <message type> <payload>
    def self.format(type, payload=nil)
      size = payload ? payload.to_s.bytes.count : 0
      msg = MAGIC_STRING + [size, type].pack("LL")
      msg << payload.to_s if payload
      msg
    end

    def format(type, payload=nil)
      self.class.format(type, payload)
    end

    # parse a full ipc response
    # similar to handle_response,
    # but parses full reply as received by EventMachine
    #
    # returns an Array containing the
    # reply type and the parsed data
    def self.parse_response(response)
      if response[0, (MAGIC_STRING.length)] != MAGIC_STRING
        raise WrongMagicCode
      end

      len, recv_type = response[6, 8].unpack("LL")

      answer = response[14, len]
      [recv_type, ::JSON.parse(answer)]
    end

    def parse_response(response)
      self.class.parse_response(response)
    end

    # writes message to the socket
    # if socket is not connected, it connects first
    def write(msg)
      connect if @socket.nil? || closed?
      @last_write_length = @socket.write msg
    end

    def read(len)
      @socket.read(len)
    end

    # connects to the given socket
    def connect
      @socket = UNIXSocket.new(@socket_path)
    end

    # closes the socket connection
    def close
      @socket.close
    end

    # alias for @socket.closed? for easy access
    def closed?
      @socket.closed?
    end
  end
end

