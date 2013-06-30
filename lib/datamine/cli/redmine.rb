require 'pry'
require 'datamine/rest/redmine'

module Datamine::CLI
  desc 'Fetch data from redmine'
  arg_name 'URL'
  command :redmine do |c|
    c.desc 'Select return format'
    c.default_value 'json'
    c.flag :format

    c.action do |global_options,options,args|
      response = Datamine::REST::Redmine.new(args.first, options[:format]).fetch

      raise "Bad HTTP response code: #{response.code}" if response.code != 200

      puts response.body
    end
  end
end
