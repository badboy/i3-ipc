require 'helper'

class TestI3IPC < Test::Unit::TestCase
  context "The I3::IPC class" do
    should "correctly format a command message" do
      assert_equal "i3-ipc\1\0\0\0\0\0\0\0l",
        I3::IPC.format(I3::IPC::MESSAGE_TYPE_COMMAND, "l")
    end

    should "correctly format a get_workspaces message" do
      assert_equal "i3-ipc\0\0\0\0\1\0\0\0",
        I3::IPC.format(I3::IPC::MESSAGE_TYPE_GET_WORKSPACES)
    end

    should "correctly format a subscribe message" do
      assert_equal "i3-ipc\0\0\0\0\2\0\0\0",
        I3::IPC.format(I3::IPC::MESSAGE_TYPE_SUBSCRIBE)
    end

    should "parse valid input" do
      assert_equal [0, { "success" => true }],
        I3::IPC.parse_response(%(i3-ipc\x10\0\0\0\0\0\0\0{"success":true}))
    end

    should "raise a WrongMagicCode exception on invalid magic string" do
      assert_raise I3::IPC::WrongMagicCode do
        I3::IPC.parse_response(%(wrong!\x10\0\0\0\0\0\0\0{"success":true}))
      end
    end

    should "raise a JSON::ParserError on invalid input" do
      assert_raise JSON::ParserError do
        I3::IPC.parse_response(%(i3-ipc\x10\0\0\0\0\0\0\0{"success :true}))
      end
    end
  end

  context "An instance of the I3::IPC class" do
    setup do
      @i3 = I3::IPC.new
    end

    should "raise an Errno::ENOENT exception with wrong socket path" do
      assert_raise Errno::ENOENT do
        i3 = I3::IPC.new("/tmp/wrong_path.sock", true)
      end
    end

    # The following tests need a running i3 instance
    # with at least one workspace

    should "correctly send a command" do
      assert_equal({ "success" => true }, @i3.command("l"))
    end

    should "correctly get the workspace list" do
      assert_nothing_raised do
        ws = @i3.get_workspaces
        assert_equal Array, ws.class
        assert_equal Hash, ws.first.class
        assert_equal true, ws.size > 0
        assert_equal true, ws.select{|e|e["focused"]}.size > 0
      end
    end

    should "correctly get the output list" do
      assert_nothing_raised do
        out = @i3.get_outputs
        assert_equal Array, out.class
        assert_equal Hash, out.first.class
        assert_equal true, out.size > 0
        assert_equal true, out.select{|e|e["active"]}.size > 0
      end
    end

  end
end
