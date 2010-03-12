require 'socket'
require 'json'
require 'i3-ipc/runner'
require 'i3-ipc/version'

module I3
  class IPC
    MAGIC_STRING = "i3-ipc"

    class WrongAnswer < RuntimeError; end # :nodoc:
    class WrongType < RuntimeError; end # :nodoc:

    # connects to the given i3 ipc interface
    # @param socket_path String the path to i3's socket
    # @param force_connect Boolean connects to the socket if true
    def initialize(socket_path="/tmp/i3-ipc.sock", force_connect=false)
      @socket_path = socket_path
      connect if connect
    end

    # send a message to i3
    #
    # the message is a command for i3
    # (like the commands you can bind to keys in the configuration file)
    # and will be executed directly after receiving it.
    #
    # returns { "success" => true }
    def message(payload)
      write format(0, payload)
      handle_response 0
    end

    # gets the current workspaces.
    # the reply will be the JSON-encoded list of workspaces
    # (see the reply section of i3 docu)
    def get_workspace
      write format(1)
      handle_response 1
    end

    # reads the reply from the socket
    # and parse the returned json into a ruby object
    #
    # throws WrongAnswer when magic word is wrong
    # throws WrongType if returned type does not match expected
    def handle_response(type)
      # reads 14 bytes
      # length of "i3-ipc" + 4 bytes length + 4 bytes type
      buffer = @socket.read 14
      raise WrongAnswer unless buffer[0, ("i3-ipc".length)]

      len, recv_type = buffer[6..-1].unpack("LL")
      raise WrongType unless recv_type == type

      answer = @socket.read(len)
      ::JSON.parse(answer)
    end

    # format the message
    # a typical message looks like
    #   "i3-ipc" <message length> <message type> <payload>
    def format(type, payload=nil)
      size = payload ? payload.to_s.bytes.count : 0
      msg = "i3-ipc%s" % [size, type].pack("LL")
      msg << payload.to_s if payload
      msg
    end

    # writes message to the socket
    # if socket is not connected, it calls conenct
    def write(msg)
      connect if @socket.nil? || closed?
      @last_write_length = @socket.write msg
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

