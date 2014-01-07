require 'httparty'

module Datamine::Jira
  module REST
    # An abstract template class that talks to v2 of the JIRA API.
    # Instantiate concrete subclasses using the module function `factory`.
    class AbstractV2
      API_PATH = 'rest/api/2'
      include HTTParty
      format :json

      def self.get_issue(issue_key)
        get "/issue/#{issue_key}"
      end

      def self.get_issue_remotelinks(issue_key)
        get "/issue/#{issue_key}/remotelink"
      end

      def self.get_search(jql_string, start_at=0, max_results=1000)
        get "/search", :query => {:jql => jql_string, :startAt => start_at, :maxResults => max_results}
      end
    end

    module_function

    # Create a concrete class that talks to a particular JIRA instance using the V2 API.
    def factory(url, username=nil, password=nil)
      Class.new(AbstractV2) do |klass|
        klass.base_uri(File.join(url, AbstractV2::API_PATH))
      end
    end
  end
end
