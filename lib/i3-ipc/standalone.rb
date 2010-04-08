module I3
  module Standalone
    extend self

    PREAMBLE = <<-preamble
#!/usr/bin/env ruby
#
# This file, i3-ipc, is generated code.
# Please DO NOT EDIT or send patches for it.
#
# Please take a look at the source from
# http://github.com/badboy/i3-ipc
# and submit patches against the individual files
# that build i3-ipc.
#

preamble

    POSTAMBLE = "I3::Runner.execute(*ARGV)\n"
    __DIR__   = File.dirname(__FILE__)
    MANPAGE   = "__END__\n#{File.read(__DIR__ + '/../../man/i3-ipc.1')}"

    def save(filename, path = '.')
      target = File.join(File.expand_path(path), filename)
      File.open(target, 'w') do |f|
        f.puts build
        f.chmod 0755
      end
    end

    def build
      root = File.dirname(__FILE__)

      standalone = ''
      standalone << PREAMBLE
      file_dir = File.expand_path(File.dirname(__FILE__))
      exclude_files = %w()

      exclude_file_list = exclude_files.map { |file|
        File.join(file_dir, file)
      } + [File.expand_path(__FILE__)]

      Dir["#{root}/../**/*.rb"].each do |file|
        # skip standalone.rb
        next if exclude_file_list.include?(File.expand_path(file))

        File.readlines(file).each do |line|
          next if line =~ /^\s*#/
          next if line =~ /^require 'i3-ipc/
          standalone << line
        end
      end

      standalone << POSTAMBLE
      standalone << MANPAGE
      standalone
    end
  end
end
