# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'whatsapp_sdk'

class Whatsapp::Client

  attr_reader :access_token, :client

  def initialize(access_token:)
    @access_token = access_token

    raise ArgumentError, __("The required parameter 'access_token' is missing.") if access_token.nil?

    @client = WhatsappSdk::Api::Client.new access_token
  end
end
