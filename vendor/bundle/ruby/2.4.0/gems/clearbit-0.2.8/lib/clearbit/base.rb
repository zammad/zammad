module Clearbit
  class Base < Resource
    endpoint 'https://api.clearbit.com'
    options :format => :json

    def self.version=(value)
      add_options headers: {'API-Version' => value}
    end

    def self.key=(value)
      add_options auth_type: :bearer,
                  password:  value

      @key = value
    end

    def self.key
      @key
    end

    def pending?
      false
    end
  end
end
