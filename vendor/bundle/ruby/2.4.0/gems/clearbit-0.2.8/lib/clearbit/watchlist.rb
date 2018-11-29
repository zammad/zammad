module Clearbit
  class Watchlist < Base
    endpoint 'https://watchlist.clearbit.com'
    path '/v1/search/all'

    def self.search(values)
      response = post('', values)
      self.new(response)
    end

    class Individual < Watchlist
      path '/v1/search/individuals'
    end

    class Entity < Watchlist
      path '/v1/search/entities'
    end

    class Candidate < Watchlist
      path '/v1/candidates'

      def self.find(id, values)
        response = get(id, values)
        self.new(response)
      end

      def self.all(values)
        response = get('', values)
        self.new(response)
      end

      def self.create(values)
        response = post('', values)
        self.new(response)
      end

      def destroy
        self.class.delete(id)
      end
    end
  end
end
