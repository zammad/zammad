# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :channel do
    area          { 'Email::Dummy' }
    group         { Group.find(1) }
    active        { true }
    options       { nil }
    preferences   { nil }
    updated_by_id { 1 }
    created_by_id { 1 }

    factory :email_channel do
      area { 'Email::Account' }
      options do
        {
          inbound:  inbound,
          outbound: outbound,
        }
      end

      transient do
        inbound do
          {
            adapter: 'null', options: {}
          }
        end

        outbound do
          {
            adapter: 'sendmail'
          }
        end
      end
    end

    factory :twitter_channel do
      area { 'Twitter::Account' }
      options do
        {
          adapter:                  'twitter',
          user:                     {
            id:          oauth_token&.split('-')&.first,
            screen_name: 'APITesting001',
            name:        'Test API Account',
          },
          auth:                     {
            external_credential_id: external_credential.id,
            oauth_token:            oauth_token,
            oauth_token_secret:     oauth_token_secret,
            consumer_key:           consumer_key,
            consumer_secret:        consumer_secret,
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
        custom_options      { {} }
        external_credential { create(:twitter_credential) }
        oauth_token         { external_credential.credentials[:oauth_token] }
        oauth_token_secret  { external_credential.credentials[:oauth_token_secret] }
        consumer_key        { external_credential.credentials[:consumer_key] }
        consumer_secret     { external_credential.credentials[:consumer_secret] }
        search_term         { 'zammad' }
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

    factory :facebook_channel do
      area { 'Facebook::Account' }
      options do
        {
          adapter: 'facebook',
          user:    {
            id:   ENV['FACEBOOK_ADMIN_USER_ID'],
            name: "#{ENV['FACEBOOK_ADMIN_FIRSTNAME']} #{ENV['FACEBOOK_ADMIN_LASTNAME']}",
          },
          auth:    {
            access_token: ENV['FACEBOOK_ADMIN_ACCESS_TOKEN'],
          },
          sync:    {
            pages: {
              ENV['FACEBOOK_PAGE_1_ID'] => {
                group_id: Group.first.id,
              }
            }
          },
          pages:   [
            {
              id:           ENV['FACEBOOK_PAGE_1_ID'],
              name:         ENV['FACEBOOK_PAGE_1_NAME'],
              access_token: ENV['FACEBOOK_PAGE_1_ACCCESS_TOKEN'],
            },
            {
              id:           ENV['FACEBOOK_PAGE_2_ID'],
              name:         ENV['FACEBOOK_PAGE_2_NAME'],
              access_token: ENV['FACEBOOK_PAGE_2_ACCCESS_TOKEN'],
            }
          ],
        }
      end
    end

    factory :google_channel do
      area { 'Google::Account' }
      options do
        {
          'inbound'  => {
            'adapter' => 'imap',
            'options' => {
              'auth_type'      => 'XOAUTH2',
              'host'           => 'imap.gmail.com',
              'ssl'            => 'ssl',
              'user'           => ENV['GMAIL_USER'],
              'folder'         => '',
              'keep_on_server' => false,
            }
          },
          'outbound' => {
            'adapter' => 'smtp',
            'options' => {
              'host'           => 'smtp.gmail.com',
              'port'           => 465,
              'ssl'            => true,
              'user'           => ENV['GMAIL_USER'],
              'authentication' => 'xoauth2',
            }
          },
          'auth'     => {
            'type'          => 'XOAUTH2',
            'provider'      => 'google',
            'access_token'  => 'xxx',
            'expires_in'    => 3599,
            'refresh_token' => ENV['GMAIL_REFRESH_TOKEN'],
            'scope'         => 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile https://mail.google.com/ openid',
            'token_type'    => 'Bearer',
            'id_token'      => 'xxx',
            'created_at'    => 30.days.ago,
            'client_id'     => ENV['GMAIL_CLIENT_ID'],
            'client_secret' => ENV['GMAIL_CLIENT_SECRET'],
          }
        }
      end
    end

    factory :microsoft365_channel do
      area { 'Microsoft365::Account' }
      options do
        {
          'inbound'  => {
            'adapter' => 'imap',
            'options' => {
              'auth_type'      => 'XOAUTH2',
              'host'           => 'outlook.office365.com',
              'ssl'            => 'ssl',
              'user'           => ENV['MICROSOFT365_USER'],
              'folder'         => '',
              'keep_on_server' => false,
            }
          },
          'outbound' => {
            'adapter' => 'smtp',
            'options' => {
              'host'           => 'smtp.office365.com',
              'port'           => 587,
              'user'           => ENV['MICROSOFT365_USER'],
              'authentication' => 'xoauth2',
            }
          },
          'auth'     => {
            'type'          => 'XOAUTH2',
            'provider'      => 'microsoft365',
            'access_token'  => 'xxx',
            'expires_in'    => 3599,
            'refresh_token' => ENV['MICROSOFT365_REFRESH_TOKEN'],
            'scope'         => 'https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access openid profile email',
            'token_type'    => 'Bearer',
            'id_token'      => 'xxx',
            'created_at'    => 30.days.ago,
            'client_id'     => ENV['MICROSOFT365_CLIENT_ID'],
            'client_secret' => ENV['MICROSOFT365_CLIENT_SECRET'],
            'client_tenant' => ENV['MICROSOFT365_CLIENT_TENANT'],
          }
        }
      end
    end

    factory :sms_message_bird_channel do
      area { 'Sms::Account' }
      status_in { 'ok' }
      status_out { 'ok' }

      options do
        {
          adapter:       'sms/message_bird',
          webhook:       "http://localhost:3000/api/v1/sms_webhook/#{webhook_token}",
          sender:        '+490123456789',
          token:         external_credential.credentials['token'],
          webhook_token: webhook_token,
        }.deep_merge(custom_options)
      end

      transient do
        custom_options      { {} }
        external_credential { create(:sms_message_bird_credential) }
        webhook_token       { Faker::Crypto.md5 }
      end
    end

    factory :telegram_channel do
      area { 'Telegram::Bot' }

      options do
        {
          bot:            {
            id:         bid,
            username:   "#{Faker::Internet.username}bot",
            first_name: Faker::Name.first_name,
            last_name:  Faker::Name.last_name,
          },
          callback_token: callback_token,
          callback_url:   "http://localhost:3000/api/v1/channels_telegram_webhook/#{callback_token}?bid=#{bid}",
          api_token:      "#{bid}:#{external_credential.credentials['api_token']}",
          welcome:        Faker::Lorem.sentence,
          goodbye:        Faker::Lorem.sentence,
        }.deep_merge(custom_options)
      end

      transient do
        custom_options      { {} }
        external_credential { create(:telegram_credential) }
        bid { Faker::Number.number(digits: 10) }
        callback_token { Faker::Alphanumeric.alphanumeric(number: 14) }
      end
    end
  end
end
