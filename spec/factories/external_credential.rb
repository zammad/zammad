FactoryBot.define do
  factory :external_credential do
    factory :facebook_credential do
      name        { 'facebook' }
      credentials { { application_id: 123, application_secret: 123 } }
    end

    factory :twitter_credential do
      name { 'twitter' }

      credentials do
        { consumer_key:       123,
          consumer_secret:    123,
          oauth_token:        123,
          oauth_token_secret: 123 }
      end
    end
  end
end
