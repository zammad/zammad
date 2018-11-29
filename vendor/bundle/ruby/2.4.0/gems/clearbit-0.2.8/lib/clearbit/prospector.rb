module Clearbit
  class Prospector < Base
    endpoint 'https://prospector.clearbit.com'
    path '/v1/people'

    def self.search(values = {})
      self.new get('search', values)
    end

    def self.find(values)
      unless values.is_a?(Hash)
        values = {:id => values}
      end

      if id = values.delete(:id)
        response = get(id, values)

      else
        raise ArgumentError, 'Invalid values'
      end

      self.new(response)
    rescue Nestful::ResourceNotFound
    end

    class << self
      alias_method :[], :find
    end

    def email
      self[:email] || email_response.email
    end

    def verified
      self[:verified] || email_response.verified
    end

    alias_method :verified?, :verified

    protected

    def email_response
      @email_response ||= begin
        response = self.class.get(uri(:email))
        Mash.new(response.decoded)
      end
    end
  end
end
