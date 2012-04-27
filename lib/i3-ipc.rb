require 'socket'
require 'json'
require_relative 'i3-ipc/runner'
require_relative 'i3-ipc/subscription'
require_relative 'i3-ipc/manpage'
require_relative 'i3-ipc/version'

module I3
  class IPC
    MAGIC_STRING = "i3-ipc"

    MESSAGE_TYPE_COMMAND = 0
    MESSAGE_TYPE_GET_WORKSPACES = 1
    MESSAGE_TYPE_SUBSCRIBE = 2
    MESSAGE_TYPE_GET_OUTPUTS = 3
    MESSAGE_TYPE_GET_TREE = 4
    MESSAGE_TYPE_GET_MARKS = 5
    MESSAGE_TYPE_GET_BAR_CONFIG = 6

    MESSAGE_REPLY_COMMAND = 0
    MESSAGE_REPLY_GET_WORKSPACES = 1
    MESSAGE_REPLY_SUBSCRIBE = 2
    MESSAGE_REPLY_GET_OUTPUTS = 3
    MESSAGE_REPLY_GET_TREE = 4
    MESSAGE_REPLY_GET_MARKS = 5
    MESSAGE_REPLY_GET_BAR_CONFIG = 6

    EVENT_MASK = (1 << 31)
    EVENT_WORKSPACE = (EVENT_MASK | 0)

    class WrongMagicCode < RuntimeError; end # :nodoc:
    class WrongType < RuntimeError; end # :nodoc:

    # Get socket path via i3 itself.
    def self.socket_path
      @@socket_path ||= `i3 --get-socketpath`.chomp
    end

    # connects to the given i3 ipc interface
    # @param socket_path String the path to i3's socket
    # @param force_connect Boolean connects to the socket if true
    def initialize(socket=nil, force_connect=false)
      @@socket_path = socket if socket
      connect if connect
    end

    # shortcut
    def self.subscribe(list, socket_path=SOCKET_PATH, &blk)
      Subscription.subscribe(list, socket_path, &blk)
    end

    # Send a command to i3.
    #
    # The payload is a command for i3
    # (like the commands you can bind to keys in the configuration file)
    # and will be executed directly after receiving it.
    #
    # Returns { "success" => true } for now.
    # i3 does send this reply without checks.
    def command(payload)
      write format(MESSAGE_TYPE_COMMAND, payload)
      handle_response MESSAGE_TYPE_COMMAND
    end

    # Gets the current workspaces.
    # The reply will be the list of workspaces
    # (see the reply section of i3 docu)
    def get_workspaces
      write format(MESSAGE_TYPE_GET_WORKSPACES)
      handle_response MESSAGE_TYPE_GET_WORKSPACES
    end

    # Gets the current outputs.
    # The reply will be a JSON-encoded list of outputs
    # (see the reply section of i3 docu).
    def get_outputs
      write format(MESSAGE_TYPE_GET_OUTPUTS)
      handle_response MESSAGE_TYPE_GET_OUTPUTS
    end

    # Gets the layout tree.
    # i3 uses a tree as data structure which includes every container.
    # The reply will be the JSON-encoded tree
    # (see the reply section of i3 docu)
    def get_tree
      write format(MESSAGE_TYPE_GET_TREE)
      handle_response MESSAGE_TYPE_GET_TREE
    end

    # Gets a list of marks (identifiers for containers to easily jump
    # to them later).
    # The reply will be a JSON-encoded list of window marks.
    # (see the reply section of i3 docu)
    def get_marks
      write format(MESSAGE_TYPE_GET_MARKS)
      handle_response MESSAGE_TYPE_GET_MARKS
    end

    # Gets the configuration (as JSON map) of the workspace bar with
    # the given ID.
    # If no ID is provided, an array with all configured bar IDs is returned instead.
    def get_bar_config id=nil
      write format(MESSAGE_TYPE_GET_BAR_CONFIG, id)
      handle_response MESSAGE_TYPE_GET_BAR_CONFIG
    end

    # Reads the reply from the socket
    # and parses the returned json into a ruby object.
    #
    # Throws WrongMagicCode when magic word is wrong.
    # Throws WrongType if returned type does not match expected.
    #
    # This is a bit duplicated code
    #  but I don't know a way to read the full send reply
    #  without knowing its length
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

    # Format the message.
    # A typical message looks like
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

    # Parse a full ipc response.
    # Similar to handle_response,
    # but parses full reply as received by EventMachine.
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

    # Writes message to the socket.
    # If socket is not connected, it connects first.
    def write(msg)
      connect if @socket.nil? || closed?
      @last_write_length = @socket.write msg
    end

    def read(len)
      @socket.read(len)
    end

    # Connects to the given socket.
    def connect
      @socket = UNIXSocket.new(self.class.socket_path)
    end

    # Closes the socket connection.
    def close
      @socket.close
    end

    # Alias for @socket.closed? for easy access
    def closed?
      @socket.closed?
    end
  end
end
