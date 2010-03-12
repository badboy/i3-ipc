require 'optparse'

module I3
  module Runner
    extend self

    def execute(*args)
      socket_file = '/tmp/i3-ipc.sock'
      type = 0
      quiet = false
      output = :default

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: i3-ipc [options] [message]"

        s_desc = 'Set socket file, defaults to /tmp/i3-ipc.sock'
        opts.on('-s', '--socket', s_desc) do |s|
          socket_file = s
        end

        t_desc = 'Set type, 0 = command, 1 = workspace list, defaults to 0'
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

        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end
      end

      opts.parse!(args)

      s = I3::IPC.new(socket_file)

      if type == 0
        if args.empty?
          abort "error: message type needs a message"
        end

        payload = args.shift

        puts s.message(payload) unless quiet
      elsif type == 1
        workspaces = s.get_workspace
        if output == :pretty_print
          require 'pp'
          pp workspaces
        elsif output == :json
          require 'json'
          puts workspaces.to_json
        else
          p workspaces
        end
      else
        abort "error: type #{type} not yet implemented"
      end
    end
  end
end
