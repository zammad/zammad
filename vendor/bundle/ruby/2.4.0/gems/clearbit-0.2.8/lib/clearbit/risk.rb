module Clearbit
  class Risk < Base
    endpoint 'https://risk.clearbit.com'
    path '/v1'

    def self.calculate(values = {})
      self.new post('calculate', values)
    end

    def self.confirmed(values = {})
      post('confirmed', values)
    end

    def self.flag(values = {})
      post('flag', values)
    end
  end
end
