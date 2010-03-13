begin
  require 'mg'
  MG.new("i3-ipc.gemspec")
rescue LoadError
  nil
end

desc "Build standalone script"
task :build => [ :standalone, :build_man ]

desc "Build standalone script"
task :standalone => :load_i3_ipc do
  require 'i3-ipc/standalone'
  I3::Standalone.save('i3-ipc')
end

desc "Build i3-ipc manual"
task :build_man do
  sh "ronn -br5 --organization=badboy --manual='i3-ipc Manual' man/*.ronn"
end

desc "Show i3-ipc manual"
task :man => :build_man do
  exec "man man/i3-ipc.1"
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
  prefix = ENV['PREFIX'] || ENV['prefix'] || '/usr/local'

  FileUtils.mkdir_p "#{prefix}/bin"
  FileUtils.cp "i3-ipc", "#{prefix}/bin"

  FileUtils.mkdir_p "#{prefix}/share/man/man1"
  FileUtils.cp "man/i3-ipc.1", "#{prefix}/share/man/man1"
end
