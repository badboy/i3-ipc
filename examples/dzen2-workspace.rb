#!/usr/bin/env ruby
# encoding: utf-8
#
# usage:
#   ruby dzen2-workspace.rb | dzen2 -ta l -dock

$LOAD_PATH.unshift File.expand_path("../lib")
require 'i3-ipc'

puts "workspace list"
$stdout.flush
I3::IPC.subscribe [:workspace] do |em, type, data|
  case type
  when I3::IPC::MESSAGE_REPLY_GET_WORKSPACES
    data.each do |e|
      if e["focused"]
        print "^fg(red)%s^fg() " % e["name"]
      else
        print "^fg(white)%s^fg() " % e["name"]
      end
    end
    puts
    $stdout.flush
  when I3::IPC::EVENT_WORKSPACE
    em.send_data I3::IPC.format(I3::IPC::MESSAGE_TYPE_GET_WORKSPACES)
  end
end
