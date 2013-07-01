require 'csv'
require 'datamine/redmine/rest'
require 'datamine/redmine/util'

module Datamine::CLI
  desc 'Fetch data from redmine'
  arg_name 'URL'
  command :redmine do |c|
    c.action do |global_options,options,args|
      # FIXME this is a hot mess.
      log_file = File.open '/tmp/issues.json', 'w' # So we have a checkpoint to recover
      log_file.write '['
      flag = false

      records = []
      attributes = Set.new

      Issues = Datamine::Redmine::REST.factory args.first

      # FIXME These need to be options!
      offset      = 0
      limit       = 100
      total_count = Issues.find(:all, :params => {:limit => 1}).total_count
      params      = {}

      Datamine::Redmine::REST.paginate(Issues, offset, limit, total_count, params) do |page|
        records += page.map do |issue|
          flag ? log_file.write(',') : (flag = true)
          log_file.write issue.to_json
          log_file.flush

          r = Datamine::Redmine::Util.flatten_issue issue
          attributes.merge r.keys
          r
        end
      end

      log_file.write ']'
      log_file.close

      $stderr.puts 'Raw data saved to /tmp/issues.json'

      CSV.open '/tmp/issues.csv', 'wb' do |csv|
        csv << attributes
        records.map do |record|
          csv << attributes.map {|k| record[k]}
        end
      end

      $stderr.puts 'Issues saved to /tmp/issues.csv'

      true
    end
  end
end
