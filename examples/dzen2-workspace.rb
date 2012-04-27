#!/usr/bin/env ruby
# encoding: utf-8
#
# usage:
#   ruby dzen2-workspace.rb | dzen2 -ta l -dock

$LOAD_PATH.unshift File.expand_path("../lib", File.dirname(__FILE__))
require 'i3-ipc'

def print_workspace_list(data)
  dzen_bg = "#111111"
  print "^pa(;2)"
  data.each do |ws|
    bg = ws["focused"] ? "#285577" : "#333333"
    fg = ws["focused"] ? "#ffffff" : "#888888"
    cmd = "i3-msg %s" % ws["num"]
    name = ws["name"]

    # Begin the clickable area
    print "^ca(1,#{cmd})"

    # Draw the rest of the bar in the background color, but
    # don’t move the "cursor"
    print "^p(_LOCK_X)^fg(#{bg})^r(1280x17)^p(_UNLOCK_X)"
    # Draw the name of the workspace without overwriting the
    # background color
    print "^p(+3)^fg(#{fg})^ib(1)#{name}^ib(0)^p(+5)"
    # Draw the rest of the bar in the normal background color
    # without moving the "cursor"
    print "^p(_LOCK_X)^fg(#{dzen_bg})^r(1280x17)^p(_UNLOCK_X)"
    # End the clickable area
    print "^ca()"
    print "^p(1)^pa(;2)"
  end

  print "^p(_LOCK_X)^fg(#{dzen_bg})^r(1280x17)^p(_UNLOCK_X)^fg(white)"
  print "^p(+5)"
  puts
  $stdout.flush
end

i3 = I3::IPC.new
print_workspace_list(i3.get_workspaces)

I3::IPC.subscribe [:workspace] do |em, type, data|
  case type
  when I3::IPC::MESSAGE_TYPE_GET_WORKSPACES
    print_workspace_list(data)
  when I3::IPC::EVENT_WORKSPACE
    em.send_data I3::IPC.format(I3::IPC::MESSAGE_TYPE_GET_WORKSPACES)
  end
end
