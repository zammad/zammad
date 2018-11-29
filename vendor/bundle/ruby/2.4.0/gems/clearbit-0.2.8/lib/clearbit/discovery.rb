require 'delegate'

module Clearbit
  class Discovery < Base
    endpoint 'https://discovery.clearbit.com'
    path '/v1/companies/search'

    class PagedResult < Delegator
      def initialize(params, response)
        @params = params
        super Mash.new(response)
      end

      def __getobj__
        @response
      end

      def __setobj__(obj)
        @response = obj
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        results.each do |result|
          yield result
        end

        if results.any?
          search = Discovery.search(
            @params.merge(page: page + 1)
          )
          search.each(&block)
        end
      end

      def map(&block)
        each.map(&block)
      end
    end

    def self.search(values = {})
      response = post('', values)

      PagedResult.new(values, response)
    end
  end
end
