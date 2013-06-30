require 'datamine/version'
require 'gli'

module Datamine::CLI
  extend GLI::App

  program_desc 'Describe your application here'

  version Datamine::VERSION
end

require 'datamine/cli/redmine'
