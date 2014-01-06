require 'csv'
require 'json'
require 'trello'

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

        board = Trello::Board.find(options[:trello][:board_id])
        list_hash = board.lists.map{|l| {l.name => l.id}}.reduce Hash.new, :merge
        existing_cards = board.cards.map{|c| c.name}

        issue_file = args.first
        case File.extname issue_file
        when '.csv'
          issues_to_add = CSV.table(issue_file).map do |row|
            {
              :name => "(#{row[:id]}) #{row[:subject]}",
              :description => "# http://projects.puppetlabs.com/issues/#{row[:id]}\n---\n#{row[:description]}",
              :project => row[:project],
            }
          end
        when '.json'
          tickets = JSON.load(File.open(issue_file, 'r') {|f| f.read})
          tickets.select! {|t| not t['pull_request']['html_url'].nil? }

          issues_to_add = tickets.map do |t|
            repo = Pathname.new(t['html_url']).dirname.dirname.basename.to_s
            {
             :name => "(#{repo}/#{t['number']}) #{t['title']}",
             :description => "# #{t['html_url']}\n---\n#{t['body']}",
             :project => 'Puppet Modules',
            }
          end
        end

        issues_to_add.each do |card|
          if existing_cards.include? card[:name]
            $stderr.puts "Issue #{card[:name].scan(/^\([\d]+\)/).first} is already on the board."
            next
          end

          begin
            target_list = list_hash[card[:project]]
            target_list ||= list_hash["Puppet"] # Dump things into the Puppet list by default

            Trello::Card.create({:name => card[:name], :list_id => target_list, :desc => card[:description]})
          rescue Trello::Error => e
            if e.to_s =~ /^invalid value for desc/
              # Sometimes, Trello can't handle the full description. Retry
              # using just the first line, which is a URL link to the Redmine
              # issue.
              $stderr.puts "Issue rejected. Retrying"
              card[:description] = card[:description].split[0]
              retry
            else
              raise e
            end
          end
        end

        $stderr.puts "There are now #{board.cards.length} cards on the board."

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

        Trello::Board.find(options[:trello][:board_id]).cards.map{|c| c.delete}
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

        Trello::Board.find(options[:trello][:board_id]).lists.map do |list|
          puts "#{list.name}: #{list.id}"
        end
      end
    end

    c.desc 'Add users to board'
    c.command :add_users do |s|
      s.action do |global_options,options,args|
        require 'addressable/uri'
        options.update YAML.load_file(File.join(ENV['HOME'], '.datamine.rc.yaml'))

        board_id = options[:trello].delete :board_id # Remove from hash so not encoded into URL
        uri = Addressable::URI.new

        CSV.table(args.first).map do |row|
          uri.query_values = { :fullName => row[:fullname], :email => row[:email], }.update options[:trello]
          puts `curl -H 'Accept: application/json' -X PUT --data '#{uri.query}' https://api.trello.com/1/board/#{board_id}/members`
        end

      end
    end

  end
end
