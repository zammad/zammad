FactoryBot.define do
  factory :external_credential do
    factory :facebook_credential do
      name        { 'facebook' }
      credentials { { application_id: 123, application_secret: 123 } }
    end

    factory :twitter_credential do
      name { 'twitter' }

      credentials do
        {
          consumer_key:       consumer_key,
          consumer_secret:    consumer_secret,
          oauth_token:        oauth_token,
          oauth_token_secret: oauth_token_secret,
          env:                'zammad',
          controller:         'external_credentials',
          action:             'app_verify',
          provider:           'twitter',
          webhook_id:         Faker::Number.number(19),
        }
      end

      # Our Twitter API tests need valid credentials,
      # but storing them in this file is bad for security.
      # So what do we do?
      #
      #   * Paste the keys in here,
      #   * run the tests (with `use_vcr: :with_oauth_headers`),
      #   * let VCR cache the network traffic, and
      #   * change the keys back to "REDACTED"
      #     (both here and in the resulting VCR cassettes).
      transient do
        consumer_key       { 'REDACTED' }
        consumer_secret    { 'REDACTED' }
        oauth_token        { 'REDACTED' }
        oauth_token_secret { 'REDACTED' }
      end

      trait :invalid do
        # If these credentials are fake/invalid,
        # why don't we use Faker to generate them dynamically?
        #
        # Our Twitter API tests use VCR to cache HTTP traffic.
        # If the values change each time you run the test,
        # VCR gets confused and raises errors.
        transient do
          consumer_key       { 'q7K8GEkhyCHs9jHLtkmD9Kod4' }
          consumer_secret    { 'LIDrpO6lRukO0PSicv00x9n8qMPvqvMq9mNInsby5sIkwN2J81' }
          oauth_token        { '7783712304-H9s75r2d532diPmJYK6JrvUWxu9gTDZ6ocjfToL' }
          oauth_token_secret { 'XFhmXR1J17zaI3bEikHKG5zNUVHVnjpzPuQc0vNmb4z2y' }
        end
      end
    end
  end
end
