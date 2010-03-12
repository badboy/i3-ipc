i3-ipc
======

inter-process communication with [i3][], the improved tiling window manager.

Installation
------------

RubyGem:

    gem install i3-ipc

Old school:

    curl -s http://github.com/badboy/i3-ipc/raw/master/i3-ipc > i3-ipc &&
    chmod 755 i3-ipc &&
    mv i3-ipc /usr/local/bin/i3-ipc

Use
---

    i3-ipc -t 1
    i3-ipc -t 1 -p
    i3-ipc -t 1 -j
    i3-ipc "exec xterm"

Contributing
------------

Once you've made your great commits:

1. [Fork][0] the project.
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create an [Issue][1] with a link to your branch
5. That's it!

Copyright
---------

Copyright (c) 2010 Jan-Erik Rediger. See LICENSE for details.

[i3]: http://i3.zekjur.net/
[0]: http://help.github.com/forking/
[1]: http://github.com/badboy/i3-ipc/issues
