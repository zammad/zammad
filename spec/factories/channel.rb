FactoryBot.define do
  factory :channel do
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
      transient do
        custom_options { {} }
      end

      area { 'Twitter::Account' }
      options do
        {
          adapter: 'twitter',
          auth:    {
            consumer_key:       'some',
            consumer_secret:    'some',
            oauth_token:        'key',
            oauth_token_secret: 'secret',
          },
          user:    {
            id:          'system_id',
            screen_name: 'system_login',
          },
          sync:    {
            import_older_tweets: true,
            track_retweets:      true,
            search:              [
              {
                term:     'zammad',
                group_id: Group.first.id
              },
              {
                term:     'hash_tag1',
                group_id: Group.first.id
              }
            ],
            mentions:            {
              group_id: Group.first.id
            },
            direct_messages:     {
              group_id: Group.first.id
            }
          }
        }.deep_merge(custom_options)
      end
    end
  end
end
