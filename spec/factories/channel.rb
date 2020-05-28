FactoryBot.define do
  factory :channel do
    # ensure the `refresh_xoaut2!` `after_initialize` callback gets executed
    # https://stackoverflow.com/questions/5916162/problem-with-factory-girl-association-and-after-initialize#comment51639005_28057070
    initialize_with { new(attributes) }

    area          { 'Email::Dummy' }
    group         { ::Group.find(1) }
    active        { true }
    options       {}
    preferences   {}
    updated_by_id { 1 }
    created_by_id { 1 }

    factory :email_channel do
      area { 'Email::Account' }
      options do
        {
          inbound:  {
            adapter: 'null', options: {}
          },
          outbound: {
            adapter: 'sendmail'
          }
        }
      end
    end

    factory :twitter_channel do
      area { 'Twitter::Account' }
      options do
        {
          adapter:                  'twitter',
          user:                     {
            id:          oauth_token&.split('-')&.first,
            screen_name: 'nicole_braun',
            name:        'Nicole Braun',
          },
          auth:                     {
            external_credential_id: external_credential.id,
            oauth_token:            oauth_token,
            oauth_token_secret:     oauth_token_secret,
          },
          sync:                     {
            webhook_id:      '',
            mentions:        {
              group_id: Group.first.id
            },
            direct_messages: {
              group_id: Group.first.id
            },
            search:          [
              {
                term:     search_term,
                group_id: Group.first.id
              },
            ],
          },
          subscribed_to_webhook_id: external_credential.credentials[:webhook_id],
        }.deep_merge(custom_options)
      end

      transient do
        custom_options { {} }
        external_credential { create(:twitter_credential) }
        oauth_token { external_credential.credentials[:oauth_token] }
        oauth_token_secret { external_credential.credentials[:oauth_token_secret] }
        search_term { 'zammad' }
      end

      trait :legacy do
        transient do
          custom_options { { sync: { import_older_tweets: true } } }
        end
      end

      trait :invalid do
        transient do
          external_credential { create(:twitter_credential, :invalid) }
        end
      end
    end
  end
end
