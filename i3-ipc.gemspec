require_relative 'lib/i3-ipc/version'
Gem::Specification.new do |s|
  s.name              = "i3-ipc"
  s.version           = I3::Version
  s.date              = Date.today.to_s
  s.summary           = "inter-process communication with i3, the improved tiling window manager."
  s.homepage          = "http://github.com/badboy/i3-ipc"
  s.email             = "badboy@archlinux.us"
  s.authors           = [ "Jan-Erik Rediger" ]
  s.has_rdoc          = false

  s.files             = %w( README.markdown Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("man/**/*")

  s.executables       = %w( i3-ipc )
  s.description       = <<desc
  uses the ipc socket of i3 to send commands or get information directly from the window manager. Useful for scripting the window manager.'
desc

  s.add_dependency "eventmachine", [">= 0.12.10"]
  s.add_development_dependency "shoulda", [">= 2.10.3"]
  s.add_development_dependency "mocha", [">= 0.9.8"]
end
