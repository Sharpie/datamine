require 'json'

require 'datamine/jira'

module Datamine::CLI
  desc 'Query JIRA issues'
  command :jira do |c|

    c.desc 'JIRA base URL'
    c.arg_name 'url_string'
    c.flag :url

    # Create a JIRA client that interacts with the API.
    pre do |global_options,command,options,args|
      url = options[:url]

      # This feels a bit weird, but can't see an obviously better way to share
      # command-global variables.
      options[:client] = Datamine::Jira::REST.factory url
      true
    end

    c.desc 'Retrieve issues from JIRA as JSON'
    c.arg_name 'jira_id', :multiple
    c.command :issue do |s|
      s.action do |global_options,options,args|
        raise 'You must specify at least one issue id' if args.empty?
        resp = args.map {|a| options[:client].get_issue(a) }

        puts JSON.pretty_generate(resp)
      end
    end

    c.desc 'Retrieve the results of a JQL query as JSON'
    c.arg_name 'query_string'
    c.command :query do |s|
      s.desc 'Zero based index of the first result to return'
      s.arg_name 'integer', :optional
      s.default_value 0
      s.flag :start_at

      s.desc 'The maximum number of results to return (may be limited by the server)'
      s.arg_name 'integer', :optional
      s.default_value 50
      s.flag :max_results

      s.action do |global_options,options,args|
        raise 'You must specify a query' if args.empty?
        resp = options[:client].get_search(args[0], options[:start_at], options[:max_results])

        puts JSON.pretty_generate(resp)
      end
    end
  end
end
