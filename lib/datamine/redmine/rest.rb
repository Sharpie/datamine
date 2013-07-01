require 'active_resource'

module Datamine::Redmine
  module REST
    # Copied directly from the ActiveResource examples of how to handle
    # non-standard data in a REST API response:
    #
    #   https://github.com/rails/activeresource/blob/v4.0.0/lib/active_resource/collection.rb#L12-L45
    class IssueCollection < ActiveResource::Collection
      attr_accessor :total_count, :offset, :limit

      def initialize(elements = {})
        @total_count = elements['total_count']
        @offset      = elements['offset']
        @limit       = elements['limit']
        @elements    = elements['issues']
      end
    end

    # Using a factory method because it is the only obvious way to dynamically
    # target a Redmine installation at runtime. Note that ActiveResource keys
    # off of the class name, so to properly fetch issues you _must_:
    #
    #     Issues = Datamine::REST::Redmine.issue_factory some_url
    def self.factory site
      Class.new(ActiveResource::Base) do
        self.site = site
        # Hard-wired to JSON as the pagination attributes (total_count, etc.)
        # embedded into XML don't survive processing to the step where our custom
        # Collection can grab them.
        self.format = :json

        # Need a custom collection parser because Redmine returns REST
        # responses that include pagination data and this violates the Rails
        # conventions.
        #
        # This extra data [can be turned off][1]:
        #
        #     self.headers['X-Redmine-Nometa'] = '1'
        #
        # But, the point of the Datamine tool is to retrieve _all_ the data.
        # So, we want pagination.
        #
        # [1]: http://www.redmine.org/issues/6140
        self.collection_parser = IssueCollection
      end
    end

    def self.paginate klass, offset, limit, total_count, params = {}
      skip = offset
      i    = 1
      n    = (total_count.to_f / limit).ceil

      while skip < total_count
        # TODO: Proper logging!
        $stderr.puts "Fetching page #{i} of #{n}"
        issues = klass.find(:all, :params => {:offset => skip, :limit => limit}.merge(params))
        yield issues
        skip += limit
        i    += 1
      end
    end

  end
end
