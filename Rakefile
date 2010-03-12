begin
  require "mg"
  MG.new("i3-ipc.gemspec")
rescue LoadError
  nil
end

desc "Build standalone script"
task :build => [ :standalone ]

desc "Build standalone script"
task :standalone => :load_i3_ipc do
  abort "not implemented yet"
  require 'i3-ipc/standalone'
  I3::Standalone.save('i3-ipc')
end

task :load_i3_ipc do
  $LOAD_PATH.unshift 'lib'
  require 'i3-ipc'
end

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

# Remove mg's install task
Rake.application.remove_task(:install)

desc "Install standalone script and man pages"
task :install => :standalone do
  abort "not implemented yet"
  #prefix = ENV['PREFIX'] || ENV['prefix'] || '/usr/local'

  #FileUtils.mkdir_p "#{prefix}/bin"
  #FileUtils.cp "i3-ipc", "#{prefix}/bin"

  # no man page yet
  #FileUtils.mkdir_p "#{prefix}/share/man/man1"
  #FileUtils.cp "man/i3-ipc.1", "#{prefix}/share/man/man1"
end
