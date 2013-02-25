require 'socket'
require 'yajl/json_gem'
require_relative 'i3-ipc/runner'
require_relative 'i3-ipc/subscription'
require_relative 'i3-ipc/manpage'
require_relative 'i3-ipc/version'

module I3
  class IPC
    MAGIC_STRING = "i3-ipc"

    COMMANDS = [
      # Send a command to i3.
      #
      # The payload is a command for i3
      # (like the commands you can bind to keys in the configuration file)
      # and will be executed directly after receiving it.
      #
      # Returns { "success" => true } for now.
      # i3 does send this reply without checks.
      [0, :command,        :required],

      # Gets the current workspaces.
      # The reply will be the list of workspaces
      # (see the reply section of i3 docu)
      [1, :get_workspaces, :none],

      # Gets the current outputs.
      # The reply will be a JSON-encoded list of outputs
      # (see the reply section of i3 docu).
      [3, :get_outputs,    :none],

      # Gets the layout tree.
      # i3 uses a tree as data structure which includes every container.
      # The reply will be the JSON-encoded tree
      # (see the reply section of i3 docu)
      [4, :get_tree,       :none],

      # Gets a list of marks (identifiers for containers to easily jump
      # to them later).
      # The reply will be a JSON-encoded list of window marks.
      # (see the reply section of i3 docu)
      [5, :get_marks,      :none],

      # Gets the configuration (as JSON map) of the workspace bar with
      # the given ID.
      # If no ID is provided, an array with all configured bar IDs is returned instead.
      [6, :get_bar_config, :optional],
    ]
    # Needed because subscribe is handled in submodule.
    MESSAGE_TYPE_SUBSCRIBE = 2

    EVENT_MASK = (1 << 31)
    EVENT_WORKSPACE = (EVENT_MASK | 0)

    def self.message_type_subscribe
      MESSAGE_TYPE_SUBSCRIBE
    end

    meta = class<<self; self; end
    COMMANDS.each do |(id, cmd, arg)|
      meta.instance_eval {
        define_method "message_type_#{cmd.downcase}" do
          id
        end
      }
      if arg == :none
        define_method cmd do
          write format(id)
          handle_response id
        end
      elsif arg == :optional || arg == :required
        define_method cmd do |arg|
          write format(id, arg)
          handle_response id
        end
      end
    end

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
    def self.subscribe(list, socket_path=nil, &blk)
      Subscription.subscribe(list, socket_path || self.socket_path, &blk)
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
