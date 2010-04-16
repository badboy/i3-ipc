require 'helper'
require 'stringio'
require 'json'
require 'tempfile'
require 'timeout'

def i3_runner_exec(args)
  I3::Runner.execute(*args)
end

class TestI3IPCCLI < Test::Unit::TestCase
  context "The I3::Runner" do
    setup do
      I3::Runner.send(:remove_const, :OUTPUT)
      @out = StringIO.new
      I3::Runner.const_set(:OUTPUT, @out)
    end

    should "print a help screen" do
      assert_raise SystemExit do
        i3_runner_exec %w[-h]
      end
      assert @out.string =~ /^Usage: i3-ipc/
    end

    should "raise an Exception on missing argument options" do
      assert_raise OptionParser::MissingArgument do
        i3_runner_exec %w[-t]
      end
    end

    should "print the workspace list" do
      i3_runner_exec %w[-t 1]
      assert @out.string =~ /\A\[\{/
    end

    should "pretty print the workspace list" do
      i3_runner_exec %w[-t 1 -p]
      # test for
      #   [{...,
      #     "...
      assert @out.string =~ /\A\[\{.+,\n\s+\"/
    end

    should "print the workspace list json-formatted" do
      i3_runner_exec %w[-t 1 -j]
      assert JSON.parse(@out.string)
    end

    should "print success on simple command" do
      i3_runner_exec %w[7]
      assert_equal %({"success"=>true}\n), @out.string
    end

    should "print nothing on simple command if told so" do
      i3_runner_exec %w[7 -q]
      assert_equal "", @out.string
    end

    should "print the output list" do
      i3_runner_exec %w[-t 3]
      assert @out.string =~ /\A\[\{/
    end

    should "pretty print the output list" do
      i3_runner_exec %w[-t 3 -p]
      # test for
      #   [{...,
      #     "...
      assert @out.string =~ /\A\[\{.+,\n\s+\"/
    end

    should "print the output list json-formatted" do
      i3_runner_exec %w[-t 3 -j]
      assert JSON.parse(@out.string)
    end

    should "accept alternative socket file" do
      assert_nothing_raised do
        i3_runner_exec %w[-s ~/.i3/ipc.sock 7]
      end
    end

    should "raise Errno::ENOENT on not existent socket file" do
      assert_raise Errno::ENOENT do
        i3_runner_exec %w[-s /tmp/invalid.sock 7]
      end
    end

    should "raise Errno::ECONNREFUSED on invalid socket file" do
      # set up invalid socket file:
      t = Tempfile.new('invalid')

      assert_raise Errno::ECONNREFUSED do
        i3_runner_exec ['-s', t.path, '7']
      end

      # ...and remove it!
      t.unlink
    end

    should "subscribe to workspace event and print list" do
      subscribe = Thread.new do
        i3_runner_exec %w[-t 2]
      end

      subscribe.run

      sleep 0.1
      I3::IPC.new.command('7')
      sleep 0.1
      EM.stop
      subscribe.kill

      assert @out.string =~ /\A\[\{/
    end

    should "subscribe to workspace event and pretty-print list" do
      subscribe = Thread.new do
        i3_runner_exec %w[-t 2 -p]
      end

      subscribe.run

      sleep 0.1
      I3::IPC.new.command('7')
      sleep 0.1
      EM.stop
      subscribe.kill

      assert @out.string =~ /\A\[\{.+,\n\s+\"/
    end

    should "subscribe to workspace event and print list json-formatted" do
      subscribe = Thread.new do
        i3_runner_exec %w[-t 2 -j]
      end

      subscribe.run

      sleep 0.1
      I3::IPC.new.command('7')
      sleep 0.1
      EM.stop
      subscribe.kill

      assert @out.string =~ /\A\[\{/
    end
  end
end
