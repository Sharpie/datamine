# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','datamine','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'datamine'
  s.version = Datamine::VERSION
  s.author = 'Charlie Sharpsteen'
  s.email = 'chuck@sharpsteen.net'
  s.homepage = 'http://www.sharpsteen.net'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
# Add your other files here if you make them
  s.files        = Dir.glob "{bin,lib}/**/*"
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'datamine'

  s.add_runtime_dependency 'gli'
  s.add_runtime_dependency 'activeresource'
  s.add_runtime_dependency 'ruby-trello'

  s.add_development_dependency 'pry'
end
