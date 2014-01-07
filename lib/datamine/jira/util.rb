require 'uri'

module Datamine::Jira
  module Util
    def summarize_issue issue
      url = URI.parse(issue['self'])

      {
        'key'         => issue['key'],
        'url'         => "#{url.scheme}://#{url.host}/browse/#{issue['key']}",
        'summary'     => issue['fields']['summary'],
        'description' => issue['fields']['description']
      }
    end

    extend self
  end
end
