module Clearbit
  module Enrichment
    class News < Base
      endpoint 'https://company.clearbit.com'
      path '/v1/news'

      def self.articles(values)
        if values.key?(:domain)
          response = get(uri(:articles), values)
        else
          raise ArgumentError, 'Invalid values'
        end

        new(response)
      end
    end
  end
end
