# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Service::Channel::Whatsapp
  class Preload < Service::Base
    attr_reader :business_id, :access_token

    def initialize(business_id:, access_token:)
      super()

      @business_id  = business_id
      @access_token = access_token
    end

    def execute
      {
        phone_numbers: formatted_phone_numbers
      }
    end

    private

    def formatted_phone_numbers
      fetch_numbers.map { |phone_number| { label: phone_number.last, value: phone_number.first } }
    end

    def fetch_numbers
      Whatsapp::Account::PhoneNumbers
        .new(business_id:, access_token:)
        .all
    end
  end
end
