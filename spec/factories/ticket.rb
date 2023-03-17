# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ticket do
    transient do
      state_name    { 'new' }
      priority_name { '2 normal' }
    end

    association :group, strategy: :create # or else build(:ticket).save fails

    customer
    title         { 'Test Ticket' }
    state         { Ticket::State.lookup(name: state_name) }
    priority      { Ticket::Priority.lookup(name: priority_name) }
    updated_by_id { 1 }
    created_by_id { 1 }

    trait :with_channel do
      transient do
        channel_name { nil }
        channel { create(channel_name) }
      end

      preferences do
        {
          channel_id: channel.id,
        }
      end
    end

    factory :twitter_ticket do
      with_channel
      channel_name { :twitter_channel }

      preferences do
        {
          channel_id:          channel.id,
          channel_screen_name: channel.options[:user][:screen_name]
        }
      end
    end

    factory :sms_ticket do
      with_channel
      channel_name { :sms_message_bird_channel }
    end

    factory :telegram_ticket do
      with_channel
      channel_name { :telegram_channel }
    end

    factory :facebook_ticket do
      with_channel
      channel_name { :facebook_channel }
    end
  end
end
