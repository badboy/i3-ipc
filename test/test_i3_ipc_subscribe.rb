# encoding: utf-8

require 'helper'
require 'stringio'
require 'json'
require 'tempfile'
require 'timeout'

def i3_runner_exec(args)
  I3::Runner.execute(*args)
end

class TestI3IPCSubscribe < Test::Unit::TestCase
  context "The I3::Runner" do
    setup do
      I3::Runner.send(:remove_const, :OUTPUT)
      @out = StringIO.new
      I3::Runner.const_set(:OUTPUT, @out)

      @socket_path = `i3 --get-socketpath`.chomp
      @current_workspace = I3::IPC.new(@socket_path).get_workspaces.find{|e|e["focused"]}["num"]
    end
    should "subscribe to workspace event and print list" do
      subscribe = Thread.new do
        i3_runner_exec ['-s', @socket_path, '-t', '2']
      end

      subscribe.run

      sleep 0.1
      I3::IPC.new(@socket_path).command("workspace #{@current_workspace+1}")
      sleep 0.1
      EM.stop
      subscribe.kill
      I3::IPC.new(@socket_path).command("workspace #{@current_workspace}")

      assert /\A\[\{/, @out.string
    end

    should "subscribe to workspace event and pretty-print list" do
      subscribe = Thread.new do
        i3_runner_exec ['-s', @socket_path, '-t', '2', '-p']
      end

      subscribe.run

      sleep 0.1
      I3::IPC.new(@socket_path).command("workspace #{@current_workspace+1}")
      sleep 0.1
      EM.stop
      subscribe.kill
      I3::IPC.new(@socket_path).command("workspace #{@current_workspace}")

      assert_match /\A\[\{.+,\n\s+\"/, @out.string #"
    end

    should "subscribe to workspace event and print list json-formatted" do
      subscribe = Thread.new do
        i3_runner_exec ['-s', @socket_path, '-t', '2', '-j']
      end

      subscribe.run

      sleep 0.1
      I3::IPC.new(@socket_path).command("workspace #{@current_workspace+1}")
      sleep 0.1
      EM.stop
      subscribe.kill
      I3::IPC.new(@socket_path).command("workspace #{@current_workspace}")

      assert_match /\A\[\{/, @out.string
    end
  end
end
