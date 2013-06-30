require 'pry'
require 'datamine/redmine/rest'

module Datamine::CLI
  desc 'Fetch data from redmine'
  arg_name 'URL'
  command :redmine do |c|
    c.action do |global_options,options,args|
      Issue = Datamine::Redmine::REST.factory args.first
      issues = Issue.find(:all)

      puts issues.to_json
    end
  end
end
