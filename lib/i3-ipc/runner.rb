require 'optparse'
require 'pp'

module I3
  module Runner
    extend self
    OUTPUT = $stdout

    def format_output(object, output, quiet)
      return if quiet
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
        when I3::IPC::MESSAGE_TYPE_GET_WORKSPACES
          format_output data, output
        when I3::IPC::EVENT_WORKSPACE
          em.send_data I3::IPC.format(I3::IPC::MESSAGE_TYPE_GET_WORKSPACES)
        end
      end
    end

    def execute(*args)
      socket_file = nil
      type = 0
      quiet = false
      output = :default

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: i3-ipc [options] [message]"

        s_desc = 'Set socket file, defaults to `i3 --get-socketpath` output'
        opts.on('-s SOCKET', '--socket SOCKET', s_desc) do |s|
          socket_file = File.expand_path(s)
        end

        t_desc = 'Set type, 0 = command, 1 = workspace list, 2 = subscribe to workspace event, 3 = output list, 4 = tree list, default: 0'
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

      socket_file ||= I3::IPC.socket_path
      i3 = I3::IPC.new(socket_file)

      if type == I3::IPC.message_type_subscribe
        subscribe socket_file, output
      else
        arg = I3::IPC::COMMANDS.find {|t| t.first == type}
        if arg
          if arg.last == :none
            format_output i3.send(arg[1]), output, quiet
          elsif arg.last == :required
            payload = args.shift
            if payload.nil?
              abort "error: payload needed."
            else
              format_output i3.send(arg[1], payload), output, quiet
            end
          elsif arg.last == :optional
            payload = args.shift
            format_output i3.send(arg[1], payload), output, quiet
          end
        end
      end
    end
  end
end
