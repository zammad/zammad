FactoryBot.define do
  factory :ticket do
    title 'Test Ticket'
    group { Group.lookup(name: 'Users') }
    customer { FactoryBot.create(:customer_user) }
    state { Ticket::State.lookup(name: 'new') }
    priority { Ticket::Priority.lookup(name: '2 normal') }
    updated_by_id 1
    created_by_id 1

    factory :twitter_ticket do
      transient do
        channel { create(:twitter_channel) }
      end

      preferences do
        {
          channel_id: channel.id,
          channel_screen_name: channel.options[:user][:screen_name]
        }
      end
    end
  end
end
