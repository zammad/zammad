# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :channel do
    area          { 'Email::Dummy' }
    group         { ::Group.find(1) }
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
              'ssl'            => true,
              'user'           => ENV['GMAIL_USER'],
              'folder'         => '',
              'keep_on_server' => false,
            }
          },
          'outbound' => {
            'adapter' => 'smtp',
            'options' => {
              'host'           => 'smtp.gmail.com',
              'domain'         => 'gmail.com',
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
              'ssl'            => true,
              'user'           => ENV['MICROSOFT365_USER'],
              'folder'         => '',
              'keep_on_server' => false,
            }
          },
          'outbound' => {
            'adapter' => 'smtp',
            'options' => {
              'host'           => 'smtp.office365.com',
              'domain'         => 'office365.com',
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
          }
        }
      end
    end
  end
end
