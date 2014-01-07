require 'csv'
require 'json'
require 'open-uri'

require 'trello'

def configure_trello options
  Trello.configure do |config|
    config.developer_public_key = options[:key]
    config.member_token = options[:token]
  end
end

module Datamine::CLI
  desc 'Manipulate Trello Boards'
  command :trello do |c|

    c.desc 'Trello API key'
    c.flag :key

    c.desc 'Trello API token'
    c.flag :token

    c.desc 'Default Trello Board'
    c.flag :board_id

    # Default action is to list all available boards
    c.default_desc 'Display available boards'
    c.action do |global_options,options,args|
      configure_trello options

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
        configure_trello options

        Trello::Board.find(options[:board_id]).lists.each {|l| puts [l.id, "\t", l.name].join}
      end
    end

    c.desc 'Purge cards from board (DANGER this is permanent)'
    c.command :purge do |s|
      s.action do |global_options,options,args|
        configure_trello options

        Trello::Board.find(options[:board_id]).cards.map{|c| c.delete}
      end
    end

    c.desc 'Export board as JSON'
    c.command :export do |s|
      s.action do |global_options,options,args|
        configure_trello options

        # From:
        #   http://www.shesek.info/general/automatically-backup-trello-lists-cards-and-other-data
        backup_url = "https://api.trello.com/1/boards/#{options[:board_id]}?key=#{options[:key]}&token=#{options[:token]}&actions=all&actions_limit=1000&cards=all&lists=all&members=all&member_fields=all&checklists=all&fields=all"
        backup_json = JSON.parse(open(backup_url).read)

        puts JSON.pretty_generate(backup_json)
      end
    end

    c.desc 'Add cards to a list on the board'
    c.arg_name 'json_file'
    c.command :add do |s|

      s.desc 'The name or id of the list to which cards should be added'
      s.arg_name 'string'
      s.flag :list

      s.action do |global_options,options,args|
        configure_trello options

        board = Trello::Board.find(options[:board_id])
        list_hash = board.lists.map{|l| {l.name => l.id}}.reduce Hash.new, :merge

        target_list = list_hash[options[:list]] || list_hash[list_hash.key(options[:list])]
        raise 'You must target this command at an existing list!' if target_list.nil?

        issue_file = args.first
        raise 'You must provide a valid json file' if issue_file.nil? || (not File.exist?(issue_file))

        tickets = JSON.parse(File.read(issue_file))

        existing_cards = board.cards.map{|c| c.name}
        tickets.each do |t|
          card = {
           :name => "(#{t['key']}) #{t['summary']}",
           :description => "# #{t['url']}\n---\n#{t['description']}",
          }

          if existing_cards.include? card[:name]
            $stderr.puts "Issue #{t['key']} is already on the board."
            next
          end

          begin
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

  #  # Everything below this line is currently broken and shouldn't be used.


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
