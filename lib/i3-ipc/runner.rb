require 'optparse'
require 'pp'

module I3
  module Runner
    extend self
    OUTPUT = $stdout

    def format_output(object, output)
      if output == :pretty_print
        PP.pp(object, OUTPUT)
      elsif output == :json
        require 'json'
        OUTPUT.puts object.to_json
      else
        OUTPUT.puts object.inspect
      end
    end

    def subscribe(path, output)
      trap('SIGINT') { EM.stop; puts }
      I3::IPC.subscribe([:workspace], path) do |em, type, data|
        case type
        when I3::IPC::MESSAGE_REPLY_GET_WORKSPACES
          format_output data, output
        when I3::IPC::EVENT_WORKSPACE
          em.send_data I3::IPC.format(I3::IPC::MESSAGE_TYPE_GET_WORKSPACES)
        end
      end
    end

    def execute(*args)
      socket_file = File.expand_path('~/.i3/ipc.sock')
      type = 0
      quiet = false
      output = :default

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: i3-ipc [options] [message]"

        s_desc = 'Set socket file, defaults to ~/.i3/ipc.sock'
        opts.on('-s SOCKET', '--socket SOCKET', s_desc) do |s|
          socket_file = File.expand_path(s)
        end

        t_desc = 'Set type, 0 = command, 1 = workspace list, 2 = subscribe to workspace event, 3 = output list, default: 0'
        opts.on('-tTYPE', '--type TYPE', Integer, t_desc) do |t|
          type = t
        end

        opts.on('-p', '--pretty-print', 'Pretty print reply') do |p|
          output = :pretty_print
        end

        opts.on('-j', '--json', 'Output raw json') do |p|
          output = :json
        end

        opts.on('-q', '--quiet', %(Don't show reply)) do |q|
          quiet = q
        end

        opts.on('-m', '--man', 'Print manual') do
          I3::Manpage.display("i3-ipc")
        end

        opts.on('-h', '--help', 'Display this screen') do
          OUTPUT.puts opts
          exit
        end
      end

      opts.parse!(args)

      s = I3::IPC.new(socket_file)

      case type
      when 0
        if args.empty?
          abort "error: message type needs a message"
        end

        payload = args.shift
        OUTPUT.puts s.command(payload).inspect unless quiet
      when I3::IPC::MESSAGE_TYPE_GET_WORKSPACES
        format_output s.get_workspaces, output
      when I3::IPC::MESSAGE_REPLY_SUBSCRIBE
        subscribe socket_file, output
      when I3::IPC::MESSAGE_TYPE_GET_OUTPUTS
        format_output s.get_outputs, output
      when I3::IPC::MESSAGE_TYPE_GET_TREE
        format_output s.get_tree, output
      else
        abort "error: type #{type} not yet implemented"
      end
    end
  end
end
