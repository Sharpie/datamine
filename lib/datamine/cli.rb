require 'datamine/version'
require 'gli'

module Datamine::CLI
  extend GLI::App

  program_desc 'A tool for extracting info from issue and task trackers.'
  config_file File.join(ENV['HOME'], '.datamine.rc.yaml')
  version Datamine::VERSION
end

require 'datamine/cli/trello'
require 'datamine/cli/jira'
#require 'datamine/cli/redmine'
