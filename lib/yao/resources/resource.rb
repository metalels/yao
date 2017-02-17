require 'time'
module Yao::Resources
  class Resource < Base
    friendly_attributes :user_id, :resource_id, :project_id,
                        :last_sample_timestamp, :first_sample_timestamp,
                        :metadata,
                        :links

    def id
      resource_id
    end

    def tenant
      @tenant ||= Yao::User.get(project_id)
    end

    def user
      @user ||= Yao::User.get(user_id)
    end

    def last_sampled_at
      Time.parse last_sample_timestamp
    end

    def first_sampled_at
      Time.parse first_sample_timestamp
    end

    def get_sample(name)
      if link = links.find{|l| l["rel"] == name }
        meter, q = link["href"].split("/").last.split("?")
        q = q.split("&").map{|v| v.split("=")}.to_a
        q.push ["q.field", "meter"]
        q.push ["q.value", meter]
        meter = nil
        Yao::Sample.list q
      end
    end

    def get_meter(name)
      if link = links.find{|l| l["rel"] == name }
        Yao::Meter.get link["href"]
      end
    end

    def meters
      links.map{|l| l["rel"] }.delete_if{|n| n == 'self' }
    end

    self.service        = "metering"
    self.api_version    = "v2"
    self.resources_name = "resources"

    class << self
      private
      def resource_from_json(json)
        json
      end

      def resources_from_json(json)
        json
      end
    end
  end
end
