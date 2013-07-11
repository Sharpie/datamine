require 'csv'
require 'trello'
require 'pry'

module Datamine::CLI
  desc 'Interact with Trello'
  command :trello do |c|
    c.desc 'Add issues to Trello'
    c.command :add do |s|
      s.action do |global_options,options,args|
        options.update YAML.load_file(File.join(ENV['HOME'], '.datamine.rc.yaml'))

        Trello.configure do |config|
          config.developer_public_key = options[:trello][:key]
          config.member_token = options[:trello][:token]
        end

        issues_to_add = CSV.table(args.first).map do |row|
          {
            :name => "(#{row[:id]}) #{row[:subject]}",
            :description => "http://projects.puppetlabs.com/issues/#{row[:id]}\n#{row[:description]}"
          }
        end

        issues_to_add.each do |card|
          begin
            Trello::Card.create({:name => card[:name], :list_id => options[:trello][:list_id], :description => card[:description]})
          rescue Trello::Error => e
            if e.to_s =~ /^invalid value for desc/
              # Sometimes, Trello can't handle the full description. Retry
              # using just the first line, which is a URL link to the Redmine
              # issue.
              card[:description] = card[:description].split[0]
              retry
            else
              raise e
            end
          end
        end

      end
    end

    c.desc 'Purge issues from Trello'
    c.command :purge do |s|
      s.action do |global_options,options,args|
        options.update YAML.load_file(File.join(ENV['HOME'], '.datamine.rc.yaml'))

        Trello.configure do |config|
          config.developer_public_key = options[:trello][:key]
          config.member_token = options[:trello][:token]
        end

        Trello::List.find(options[:trello][:list_id]).cards.map{|c| c.delete}
      end
    end

    c.desc 'List available lists'
    c.command :list do |s|
      s.action do |global_options,options,args|
        options.update YAML.load_file(File.join(ENV['HOME'], '.datamine.rc.yaml'))

        Trello.configure do |config|
          config.developer_public_key = options[:trello][:key]
          config.member_token = options[:trello][:token]
        end

        Trello::List.find(options[:trello][:list_id]).board.lists.map do |list|
          puts "#{list.name}: #{list.id}"
        end
      end
    end
  end
end
