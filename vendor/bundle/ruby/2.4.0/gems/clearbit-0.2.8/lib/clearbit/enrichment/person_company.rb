module Clearbit
  module Enrichment
    class PersonCompany < Base
      endpoint 'https://person.clearbit.com'
      path '/v2/combined'

      def self.find(values)
        unless values.is_a?(Hash)
          values = { email: values }
        end

        if values.key?(:email)
          response = get(uri(:find), values)
        else
          raise ArgumentError, 'Invalid values'
        end

        if response.status == 202
          Pending.new
        else
          self.new(response)
        end
      rescue Nestful::ResourceNotFound
      end

      class << self
        alias_method :[], :find
      end
    end
  end
end
