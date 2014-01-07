source 'https://rubygems.org'

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end

gemspec

# Pin gems so that the tool works on 1.8.7
gem 'mime-types', '~> 1.0'
