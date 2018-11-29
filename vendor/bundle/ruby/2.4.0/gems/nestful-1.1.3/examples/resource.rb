require 'nestful'

# Example of using Stripe's API

class Base < Nestful::Resource
  endpoint 'https://api.stripe.com'
  options :auth_type => :bearer, :password => ENV['SECRET_KEY']

  def self.all(*args)
    # We have to delve into the response,
    # as Stripe doesn't return arrays for
    # list responses.
    self.new(Base.new(get('', *args)).data)
  end

  def self.find(id)
    self.new(get(id))
  end
end

class Charge < Base
  path '/v1/charges'

  def refund
    post(:refund)
  end
end

class Token < Base
  path '/v1/tokens'
end