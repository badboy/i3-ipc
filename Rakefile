#begin
  #require 'mg'
  #MG.new("i3-ipc.gemspec")

  #desc "Build a gem."
  #task :gem => :package

  #desc "Push a new version to Gemcutter and publish docs."
  #task :publish => [:test, :gemcutter] do
    #require_relative 'lib/i3-ipc/version'

    #sh "git tag v#{I3::Version}"
    #sh "git push origin master --tags"
    #sh "git clean -fd"
    #exec "rake pages"
  #end
#rescue LoadError => e
  #raise unless e.message =~ /-- mg$/
  #warn "mg not available."
  #warn "Install it with: gem i mg"
#end

desc "Build standalone script"
task :build => [ "build:standalone", "build:man" ]

desc "Show i3-ipc manual"
task :man => "build:man" do
  exec "man man/i3-ipc.1"
end

file "i3-ipc" => FileList.new("lib/i3-ipc.rb", "lib/i3-ipc/*.rb", "man/i3-ipc.1") do |task|
  require_relative 'lib/i3-ipc/standalone'
  I3::Standalone.save(task.name)
end

namespace :build do
  desc "Build i3-ipc manual"
  task :man do
    sh "ronn -br5 --organization=badboy --manual='i3-ipc Manual' man/*.ronn"
  end

  desc "Build standalone script"
  task :standalone => "i3-ipc"
end

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

# Remove mg's install task
Rake.application.remove_task(:install)

desc "Install standalone script and man pages"
task :install => "build:standalone" do
  prefix = ENV['PREFIX'] || ENV['prefix'] || '/usr/local'

  FileUtils.mkdir_p "#{prefix}/bin"
  FileUtils.cp "i3-ipc", "#{prefix}/bin"

  FileUtils.mkdir_p "#{prefix}/share/man/man1"
  FileUtils.cp "man/i3-ipc.1", "#{prefix}/share/man/man1"
end

desc "Publish to GitHub Pages"
task :pages => [ "build:man" ] do
  Dir['man/*.html'].each do |f|
    cp f, File.basename(f).sub('.html', '.newhtml')
  end

  `git commit -am 'generated manual'`
  `git checkout gh-pages`

  Dir['*.newhtml'].each do |f|
    mv f, "index.html"
  end

  `git add .`
  `git commit -m updated`
  `git push origin gh-pages`
  `git checkout master`
  puts :done
end

desc "fire up IRB console"
task :console do
  exec "irb -Ilib -ri3-ipc"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end
