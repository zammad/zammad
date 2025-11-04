# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :external_credential do
    factory :facebook_credential do
      name        { 'facebook' }
      credentials { { application_id: 123, application_secret: 123 } }
    end

    factory :sms_message_bird_credential do
      name        { 'message_bird' }
      credentials { { token: Faker::Alphanumeric.alphanumeric(number: 25) } }
    end

    factory :telegram_credential do
      name        { 'telegram' }
      credentials { { api_token: "#{Faker::Alphanumeric.alphanumeric(number: 7)}-#{Faker::Alphanumeric.alphanumeric(number: 13)}_#{Faker::Alphanumeric.alphanumeric(number: 7)}_#{Faker::Alphanumeric.alphanumeric(number: 5)}" } }
    end

    factory :microsoft_graph_credential do
      name { 'microsoft_graph' }

      transient do
        client_id     { SecureRandom.uuid }
        client_secret { SecureRandom.urlsafe_base64(40) }
        client_tenant { SecureRandom.uuid }
      end

      credentials do
        {
          'client_id'     => client_id,
          'client_secret' => client_secret,
          'client_tenant' => client_tenant,
          'controller'    => 'external_credentials',
          'action'        => 'app_verify',
          'provider'      => 'microsoft_graph',
        }
      end
    end

    factory :microsoft365_credential do
      name { 'microsoft365' }

      transient do
        client_id     { SecureRandom.uuid }
        client_secret { SecureRandom.urlsafe_base64(40) }
        client_tenant { SecureRandom.uuid }
      end

      credentials do
        {
          'client_id'     => client_id,
          'client_secret' => client_secret,
          'client_tenant' => client_tenant,
          'controller'    => 'external_credentials',
          'action'        => 'app_verify',
          'provider'      => 'microsoft365',
        }
      end
    end

    factory :google_credential do
      name { 'google' }

      transient do
        client_id     { SecureRandom.uuid }
        client_secret { SecureRandom.urlsafe_base64(40) }
      end

      credentials do
        {
          'client_id'     => client_id,
          'client_secret' => client_secret,
          'controller'    => 'external_credentials',
          'action'        => 'app_verify',
          'provider'      => 'google',
        }
      end
    end
  end
end
