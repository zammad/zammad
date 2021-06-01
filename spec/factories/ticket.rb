# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

    factory :twitter_ticket do
      transient do
        channel { create(:twitter_channel) }
      end

      preferences do
        {
          channel_id:          channel.id,
          channel_screen_name: channel.options[:user][:screen_name]
        }
      end
    end
  end
end
