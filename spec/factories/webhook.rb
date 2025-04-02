# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :webhook do
    sequence(:name)    { |n| "Test webhook #{n}" }
    endpoint           { 'http://example.com/endpoint' }
    ssl_verify         { true }
    active             { true }
    created_by_id      { 1 }
    updated_by_id      { 1 }
    custom_payload     { nil }
    customized_payload { false }

    factory :mattermost_webhook do
      name                     { 'Mattermost Notifications' }
      endpoint                 { 'https://example.com/mattermost' }
      pre_defined_webhook_type { 'Mattermost' }
      note                     { 'Pre-defined webhook for Mattermost Notifications.' }
      preferences do
        {
          pre_defined_webhook: {
            messaging_username: Faker::Internet.unique.username,
            messaging_channel:  Faker::Internet.unique.slug,
            messaging_icon_url: Faker::Internet.unique.url,
          },
        }
      end
    end

    factory :ms_teams_webhook do
      name                     { 'Microsoft Teams Notifications' }
      endpoint                 { 'https://example.com/msteams' }
      pre_defined_webhook_type { 'MicrosoftTeams' }
      note                     { 'Pre-defined webhook for Microsoft Teams Notifications.' }
    end

    factory :rocketchat_webhook do
      name                     { 'Rocket Chat Notifications' }
      endpoint                 { 'https://example.com/rocket_chat' }
      pre_defined_webhook_type { 'RocketChat' }
      note                     { 'Pre-defined webhook for Rocket Chat Notifications.' }
      preferences do
        {
          pre_defined_webhook: {
            messaging_username: Faker::Internet.unique.username,
            messaging_channel:  Faker::Internet.unique.slug,
            messaging_icon_url: Faker::Internet.unique.url,
          },
        }
      end
    end

    factory :slack_webhook do
      name                     { 'Slack Notifications' }
      endpoint                 { 'https://example.com/slack' }
      pre_defined_webhook_type { 'Slack' }
      note                     { 'Pre-defined webhook for Slack Notifications.' }
    end
  end
end
