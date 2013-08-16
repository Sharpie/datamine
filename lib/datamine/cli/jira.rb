require 'net/http'
require 'uri'
require 'json'

module Datamine::CLI
  desc 'Post test issue to JIRA'
  command :jira do |c|
    c.action do |global_options,options,args|
      options.update YAML.load_file(File.join(ENV['HOME'], '.datamine.rc.yaml'))

      issue_data = {
        "fields" => {
          "project" =>
          {
            "key" => "TEST"
          },
          "summary" => "REST ye merry gentlemen.",
          "description" => "Creating of an issue using project keys and issue type names using the REST API",
          "issuetype" => {
            "name" => "Bug"
          }
        }
      }

      remote_link = {
        'object' => {
          'url'   => 'http://projects.puppetlabs.com/issues/15106',
          'title' => "Missing site.pp can cause error 'Cannot find definition Class'",
        }
      }

      jira = URI.parse options[:jira][:url]
      http = Net::HTTP.new jira.host, jira.port
      http.use_ssl = true

      request = Net::HTTP::Post.new File.join(jira.request_uri, 'issue')
      request.basic_auth options[:jira][:username], options[:jira][:password]
      request.body = issue_data.to_json
      request['content-type'] = 'application/json'

      resp = http.request request
      unless resp.kind_of? Net::HTTPSuccess
        $stderr.puts 'Issue creation failed!'
        return false
      end

      key = JSON.load(resp.body)['key']

      request = Net::HTTP::Post.new File.join(jira.request_uri, 'issue', key, 'remotelink')
      request.basic_auth options[:jira][:username], options[:jira][:password]
      request.body = remote_link.to_json
      request['content-type'] = 'application/json'

      resp = http.request request

      unless resp.kind_of? Net::HTTPSuccess
        $stderr.puts 'Issue linking failed!'
        return false
      end

      true
    end
  end
end
