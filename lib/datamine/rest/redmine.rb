require 'httparty'

module Datamine::REST
  class Redmine
    include HTTParty

    def initialize url, format
      @format = format
      self.class.base_uri 'http://projects.puppetlabs.com'
    end

    def fetch
      self.class.get "/issues.#{@format}"
    end
  end
end
