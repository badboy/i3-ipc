i3-ipc
======

inter-process communication with [i3][], the improved tiling window manager.

Installation
------------

RubyGem:

    gem install i3-ipc

Old school (for the cli script only):

    curl -s http://github.com/badboy/i3-ipc/raw/master/i3-ipc > i3-ipc &&
    chmod 755 i3-ipc &&
    mv i3-ipc /usr/local/bin/i3-ipc

Use
---

    i3-ipc -t 1
    i3-ipc -t 1 -p
    i3-ipc -t 1 -j
    i3-ipc "exec xterm"

Read the [man-page]() for more information.

Subscribing
-----------

As of commit [3db4890]() i3 added events.
For now there's only one event: `workspace`.

According to the documentation:
> This event is sent when the user switches to a different workspace, when a new workspace is initialized or when a workspace is removed (because the last client vanished).

i3-ipc uses [EventMachine][em] to receive and handle these events.

With `i3-ipc`'s interface and EventMachine as its backend it's rather easy to subscribe to this event notifying:

    I3::IPC.subscribe [:workspace] do |em, type, data|
      # ...
    end

There are 3 arguments passed to the block:

* `em` is the instance of the EM::Connection class.
To send data to the socket, you need to use `em.send_data`.
* `type` is the received message type.
This could be one of
  * MESSAGE_REPLY_COMMAND
  * MESSAGE_REPLY_COMMAND
  * MESSAGE_REPLY_COMMAND
  * EVENT_WORKSPACE #_
* `data` is the received data, already parsed.

For example you can use the following code to get the actual focused screen:

    I3::IPC.subscribe [:workspace] do |em, type, data|
      case type
      when I3::IPC::MESSAGE_REPLY_GET_WORKSPACES
        data.each do |e|
          if e["focused"]
            puts "focused: %s" % e["name"]
          else
            puts "unfocused: %s" % e["name"]
          end
        end
      when I3::IPC::EVENT_WORKSPACE
        em.send_data I3::IPC.format(I3::IPC::MESSAGE_TYPE_GET_WORKSPACES)
      end
    end

A full example of how this can be used for the workspace bar can be found in the `examples` directory.

You can use `EM.stop` to stop the connection.


What needs to be done?
----------------------

* cleanup the subscribtion frontend
* write tests
* …

Contributing
------------

Once you've made your great commits:

1. [Fork]() the project.
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create an [Issue]() with a link to your branch
5. That's it!

Copyright
---------

Copyright (c) 2010 Jan-Erik Rediger. See LICENSE for details.

[i3]: http://i3.zekjur.net/
[manpage]: http://badboy.github.com/i3-ipc/
[3db4890]: http://code.stapelberg.de/git/i3/commit/?h=next&id=3db4890683e87
[em]: http://github.com/eventmachine/eventmachine
[fork]: http://help.github.com/forking/
[issue]: http://github.com/badboy/i3-ipc/issues
