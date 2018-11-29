module Clearbit
  class Reveal < Base
    endpoint 'https://reveal.clearbit.com'
    path '/v1/companies'

    def self.find(values)
      self.new(get(:find, values))
    rescue Nestful::ResourceNotFound
    end

    class << self
      alias_method :[], :find
    end
  end
end
