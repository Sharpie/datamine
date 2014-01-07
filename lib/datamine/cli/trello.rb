require 'csv'
require 'json'
require 'open-uri'

require 'trello'

module Datamine::CLI
  desc 'Manipulate Trello Boards'
  command :trello do |c|

    c.desc 'Trello API key'
    c.flag :key

    c.desc 'Trello API token'
    c.flag :token

    c.desc 'Default Trello Board'
    c.flag :board_id

    pre do |global_options,command,options,args|
      Trello.configure do |config|
        config.developer_public_key = options[:key]
        config.member_token = options[:token]
      end
    end

    # Default action is to list all available boards
    c.default_desc 'Display available boards'
    c.action do |global_options,options,args|
      Trello::Board.all.each do |b|
        info = [b.id, "\t", b.name]
        # Mark archived boards
        info << [" (closed)"] if b.closed
        puts info.join
      end
    end

    c.desc 'Display lists on board'
    c.command :lists do |s|
      s.action do |global_options,options,args|
        Trello::Board.find(options[:board_id]).lists.each {|l| puts [l.id, "\t", l.name].join}
      end
    end

    c.desc 'Purge cards from board (DANGER this is permanent)'
    c.command :purge do |s|
      s.action do |global_options,options,args|
        Trello::Board.find(options[:board_id]).cards.map{|c| c.delete}
      end
    end

    c.desc 'Export board as JSON'
    c.command :export do |s|
      s.action do |global_options,options,args|
        # From:
        #   http://www.shesek.info/general/automatically-backup-trello-lists-cards-and-other-data
        backup_url = "https://api.trello.com/1/boards/#{options[:board_id]}?key=#{options[:key]}&token=#{options[:token]}&actions=all&actions_limit=1000&cards=all&lists=all&members=all&member_fields=all&checklists=all&fields=all"
        backup_json = JSON.parse(open(backup_url).read)

        puts JSON.pretty_generate(backup_json)
      end
    end

  #  # Everything below this line is currently broken and shouldn't be used.

  #  c.desc 'Add issues to Trello'
  #  c.command :add do |s|
  #    s.action do |global_options,options,args|
  #      board = Trello::Board.find(options[:trello][:board_id])
  #      list_hash = board.lists.map{|l| {l.name => l.id}}.reduce Hash.new, :merge
  #      existing_cards = board.cards.map{|c| c.name}

  #      issue_file = args.first
  #      case File.extname issue_file
  #      when '.csv'
  #        issues_to_add = CSV.table(issue_file).map do |row|
  #          {
  #            :name => "(#{row[:id]}) #{row[:subject]}",
  #            :description => "# http://projects.puppetlabs.com/issues/#{row[:id]}\n---\n#{row[:description]}",
  #            :project => row[:project],
  #          }
  #        end
  #      when '.json'
  #        tickets = JSON.load(File.open(issue_file, 'r') {|f| f.read})
  #        tickets.select! {|t| not t['pull_request']['html_url'].nil? }

  #        issues_to_add = tickets.map do |t|
  #          repo = Pathname.new(t['html_url']).dirname.dirname.basename.to_s
  #          {
  #           :name => "(#{repo}/#{t['number']}) #{t['title']}",
  #           :description => "# #{t['html_url']}\n---\n#{t['body']}",
  #           :project => 'Puppet Modules',
  #          }
  #        end
  #      end

  #      issues_to_add.each do |card|
  #        if existing_cards.include? card[:name]
  #          $stderr.puts "Issue #{card[:name].scan(/^\([\d]+\)/).first} is already on the board."
  #          next
  #        end

  #        begin
  #          target_list = list_hash[card[:project]]
  #          target_list ||= list_hash["Puppet"] # Dump things into the Puppet list by default

  #          Trello::Card.create({:name => card[:name], :list_id => target_list, :desc => card[:description]})
  #        rescue Trello::Error => e
  #          if e.to_s =~ /^invalid value for desc/
  #            # Sometimes, Trello can't handle the full description. Retry
  #            # using just the first line, which is a URL link to the Redmine
  #            # issue.
  #            $stderr.puts "Issue rejected. Retrying"
  #            card[:description] = card[:description].split[0]
  #            retry
  #          else
  #            raise e
  #          end
  #        end
  #      end

  #      $stderr.puts "There are now #{board.cards.length} cards on the board."

  #    end
  #  end

  #  c.desc 'Add users to board'
  #  c.command :add_users do |s|
  #    s.action do |global_options,options,args|
  #      require 'addressable/uri'
  #      uri = Addressable::URI.new

  #      CSV.table(args.first).map do |row|
  #        uri.query_values = { :fullName => row[:fullname], :email => row[:email], }.update options[:trello]
  #        puts `curl -H 'Accept: application/json' -X PUT --data '#{uri.query}' https://api.trello.com/1/board/#{board_id}/members`
  #      end

  #    end
  #  end

  end
end
