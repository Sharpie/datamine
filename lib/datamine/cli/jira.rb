require 'json'

require 'datamine/jira'

# Create a JIRA client that interacts with the API.
def configure_jira options
  url = options[:url]

  # This feels a bit weird, but can't see an obviously better way to share
  # command-global variables.
  options[:client] = Datamine::Jira::REST.factory url
end


module Datamine::CLI
  desc 'Query JIRA issues'
  command :jira do |c|

    c.desc 'JIRA base URL'
    c.arg_name 'url_string'
    c.flag :url

    c.desc 'Summary mode. Munge JSON to a reduced, standardized form.'
    c.default_value false
    c.switch :s, :negatable => false

    c.desc 'Retrieve issues from JIRA as JSON'
    c.arg_name 'jira_id', :multiple
    c.command :issue do |s|
      s.action do |global_options,options,args|
        configure_jira options

        raise 'You must specify at least one issue id' if args.empty?
        resp = args.map do |i|
          issue = options[:client].get_issue(i)
          issue = Datamine::Jira::Util.summarize_issue(issue) if options[:s]
          issue
        end

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
        configure_jira options

        raise 'You must specify a query' if args.empty?
        resp = options[:client].get_search(args[0], options[:start_at], options[:max_results])
        resp = resp['issues'].map {|i| Datamine::Jira::Util.summarize_issue(i)} if options[:s]

        puts JSON.pretty_generate(resp)
      end
    end
  end
end
