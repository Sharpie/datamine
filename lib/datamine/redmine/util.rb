module Datamine::Redmine
  module Util
    def flatten_issue issue
      flat_hash = {}
      issue.serializable_hash.each do |k, v|
        if v.respond_to? :attributes
          flat_hash[k] = v.attributes[:name]
        elsif k == 'custom_fields'
          v.map {|f| flat_hash[f.attributes[:name]] = f.attributes[:value] }
        else
          flat_hash[k] = v
        end
      end
      flat_hash
    end

    extend self
  end
end
