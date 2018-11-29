module Clearbit
  class NameDomain < Base
    endpoint 'https://company.clearbit.com'
    path '/v1/domains'

    def self.find(values)
      response = get(uri(:find), values)
      Mash.new(response.decoded)
    rescue Nestful::ResourceNotFound
    end

    class << self
      alias_method :[], :find
    end
  end
end

