# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'ticket/article', aliases: %i[ticket_article] do
    inbound_email

    association :ticket, strategy: :create # or else build(:ticket_article).save fails
    from          { 'factory-customer-1@example.com' }
    to            { 'factory-customer-1@example.com' }
    subject       { 'factory article' }

    message_id    { 'factory@id_com_1' }
    body          { 'some message 123' }
    internal      { false }
    sender        { Ticket::Article::Sender.find_by(name: sender_name) }
    type          { Ticket::Article::Type.find_by(name: type_name) }
    updated_by_id { 1 }
    created_by_id { 1 }

    trait :inbound_email do
      transient do
        type_name   { 'email' }
        sender_name { 'Customer' }
      end
    end

    trait :outbound_email do
      transient do
        type_name   { 'email' }
        sender_name { 'Agent' }
      end

      from { ticket.group.name }
      to   { "#{ticket.customer.fullname} <#{ticket.customer.email}>" }
    end

    trait :inbound_phone do
      transient do
        type_name { 'phone' }
        sender_name { 'Customer' }
      end
    end

    trait :outbound_phone do
      transient do
        type_name   { 'phone' }
        sender_name { 'Agent' }
      end

      from { nil }
      to   { ticket.customer.fullname }
    end

    trait :outbound_note do
      transient do
        type_name   { 'note' }
        sender_name { 'Agent' }
      end

      from { ticket.group.name }
    end

    trait :internal_note do
      transient do
        type_name   { 'note' }
        sender_name { 'Agent' }
      end

      from     { ticket.group.name }
      internal { true }
    end

    trait :inbound_web do
      transient do
        type_name   { 'web' }
        sender_name { 'Customer' }
      end
    end

    trait :outbound_web do
      transient do
        type_name   { 'web' }
        sender_name { 'Agent' }
      end
    end

    factory :twitter_article do
      transient do
        type_name   { 'twitter status' }
        sender_name { 'Agent' }
      end

      association :ticket, factory: :twitter_ticket
      subject      { nil }
      body         { Faker::Lorem.sentence }
      content_type { 'text/plain' }
      message_id   { Faker::Number.number(digits: 18) }

      after(:create) do |article, context|
        next if context.sender_name == 'Agent'

        context.ticket.title = article.body

        context.ticket.save!
      end

      trait :inbound do
        transient do
          sender_name  { 'Customer' }
          username     { Faker::Twitter.screen_name }
          sender_id    { Faker::Number.number(digits: 18) }
          recipient_id { Faker::Number.number(digits: 19) }
        end

        from { "@#{username}" }
        to   { "@#{ticket.preferences['channel_screen_name']}" }
        body { "#{to} #{Faker::Lorem.question}" }

        preferences do
          {
            twitter: {
              mention_ids:         [recipient_id],
              geo:                 {},
              retweeted:           false,
              possibly_sensitive:  false,
              in_reply_to_user_id: recipient_id,
              place:               {},
              retweet_count:       0,
              source:              '<a href="https://mobile.twitter.com" rel="nofollow">Twitter Web App</a>',
              favorited:           false,
              truncated:           false
            },
            links:   [
              {
                url:    "https://twitter.com/_/status/#{sender_id}",
                target: '_blank',
                name:   'on Twitter',
              },
            ],
          }
        end
      end

      trait :outbound do
        transient do
          username     { Faker::Twitter.screen_name }
          sender_id    { Faker::Number.number(digits: 18) }
          recipient_id { Faker::Number.number(digits: 19) }
        end

        from        { "@#{ticket.preferences['channel_screen_name']}" }
        to          { "@#{username}" }
        body        { "#{to} #{Faker::Lorem.sentence}" }
        in_reply_to { Faker::Number.number(digits: 19) }

        preferences do
          {
            twitter: {
              mention_ids:         [recipient_id],
              geo:                 {},
              retweeted:           false,
              possibly_sensitive:  false,
              in_reply_to_user_id: recipient_id,
              place:               {},
              retweet_count:       0,
              source:              '<a href="https://www.canva.com" rel="nofollow">Canva</a>',
              favorited:           false,
              truncated:           false
            },
            links:   [
              {
                url:    "https://twitter.com/_/status/#{sender_id}",
                target: '_blank',
                name:   'on Twitter',
              },
            ],
          }
        end
      end

      trait :reply do
        in_reply_to { Faker::Number.number(digits: 19) }
      end
    end

    factory :twitter_dm_article do
      transient do
        type_name { 'twitter direct-message' }
      end

      association :ticket, factory: :twitter_ticket
      body { Faker::Lorem.sentence }

      trait :pending_delivery do
        transient do
          recipient { create(:twitter_authorization) }
          sender_id { Faker::Number.number(digits: 10) }
        end

        from         { ticket.owner.fullname }
        to           { recipient.username }
        in_reply_to  { Faker::Number.number(digits: 19) }
        content_type { 'text/plain' }
      end

      trait :delivered do
        pending_delivery
        message_id { Faker::Number.number(digits: 19) }
        preferences do
          {
            delivery_retry:          1,
            twitter:                 {
              recipient_id: recipient.uid,
              sender_id:    sender_id
            },
            links:                   [
              {
                url:    "https://twitter.com/messages/#{recipient.uid}-#{sender_id}",
                target: '_blank',
                name:   'on Twitter'
              }
            ],
            delivery_status_message: nil,
            delivery_status:         'success',
            delivery_status_date:    Time.current
          }
        end
      end
    end

    factory :sms_article do
      inbound

      transient do
        type_name { 'sms' }
      end

      association :ticket, factory: :sms_ticket
      from { Faker::PhoneNumber.cell_phone_in_e164 }
      to   { Faker::PhoneNumber.cell_phone_in_e164 }
      subject { nil }
      body { Faker::Lorem.sentence }
      message_id { Faker::Number.number(digits: 19) }
      content_type { 'text/plain' }

      after(:create) do |article, context|
        next if context.sender_name == 'Agent'

        context.ticket.title = article.body
        context.ticket.preferences.tap do |p|
          p['sms'] = {
            originator: article.from,
            recipient:  article.to,
          }
        end

        context.ticket.save!
      end

      trait :inbound do
        transient do
          sender_name { 'Customer' }
        end

        preferences do
          {
            channel_id: ticket.preferences['channel_id'],
            sms:        {
              reference: message_id,
            },
          }
        end
      end

      trait :outbound do
        transient do
          sender_name { 'Agent' }
        end

        in_reply_to { Faker::Number.number(digits: 19) }

        preferences do
          {
            delivery_retry:          1,
            delivery_status_message: nil,
            delivery_status:         'success',
            delivery_status_date:    Time.current,
          }
        end
      end
    end

    factory :telegram_article do
      inbound

      transient do
        type_name { 'telegram personal-message' }
        channel { Channel.find(ticket.preferences[:channel_id]) }
        username { Faker::Internet.username }
      end

      association :ticket, factory: :telegram_ticket
      to { "@#{channel[:options][:bot][:username]}" }
      subject { nil }
      body { Faker::Lorem.sentence }
      message_id { "#{Faker::Number.decimal(l_digits: 1, r_digits: 10)}@telegram" }
      content_type { 'text/plain' }

      after(:create) do |article, context|
        next if context.sender_name == 'Agent'

        context.ticket.title = article.body
        context.ticket.preferences.tap do |p|
          p['telegram'] = {
            bid:     context.channel[:options][:bot][:id],
            chat_id: (article.preferences[:telegram] && article.preferences[:telegram][:chat_id]) || Faker::Number.number(digits: 10),
          }
        end

        context.ticket.save!
      end

      trait :inbound do
        transient do
          sender_name { 'Customer' }
        end

        created_by_id { ticket.customer_id } # NB: influences the value for the from field!

        preferences do
          {
            message:   {
              created_at: Time.current.to_i,
              message_id: message_id,
              from:       ActionController::Parameters.new(
                'id'            => Faker::Number.number,
                'is_bot'        => false,
                'first_name'    => Faker::Name.first_name,
                'last_name'     => Faker::Name.last_name,
                'username'      => username,
                'language_code' => 'en',
              ),
            },
            update_id: Faker::Number.number(digits: 8),
          }
        end
      end

      trait :outbound do
        transient do
          sender_name { 'Agent' }
        end

        to { "@#{username}" }
        created_by_id { create(:agent).id } # NB: influences the value for the from field!
        in_reply_to { "#{Faker::Number.decimal(l_digits: 1, r_digits: 10)}@telegram" }

        preferences do
          {
            delivery_retry:          1,
            telegram:                {
              date:       Time.current.to_i,
              from_id:    Faker::Number.number(digits: 10),
              chat_id:    Faker::Number.number(digits: 10),
              message_id: Faker::Number.number,
            },
            delivery_status_message: nil,
            delivery_status:         'success',
            delivery_status_date:    Time.current,
          }
        end
      end
    end

    factory :facebook_article do
      inbound

      transient do
        channel { Channel.find(ticket.preferences[:channel_id]) }
        post_id { Faker::Number.number(digits: 15) }
        permalink_url { "https://www.facebook.com/#{channel[:options][:pages][0][:id]}/posts/#{post_id}/?comment_id=#{post_id}" }
      end

      association :ticket, factory: :facebook_ticket
      subject { nil }
      body { Faker::Lorem.sentence }
      message_id { "#{Faker::Number.number(digits: 16)}_#{Faker::Number.number(digits: 15)}" }
      content_type { 'text/plain' }

      after(:create) do |article, context|
        next if context.sender_name == 'Agent'

        context.ticket.title = article.body
        context.ticket.preferences.tap do |p|
          p['channel_fb_object_id'] = context.post_id,
                                      p['facebook'] = {
                                        permalink_url: context.permalink_url,
                                      }
        end

        context.ticket.save!
      end

      trait :inbound do
        transient do
          type_name { 'facebook feed post' }
          sender_name { 'Customer' }
        end

        from { ticket.customer.fullname }
        to { channel[:options][:pages][0][:name] }

        preferences do
          {
            links: [
              {
                url:    permalink_url,
                target: '_blank',
                name:   'on Facebook',
              },
            ],
          }
        end
      end

      trait :outbound do
        transient do
          type_name { 'facebook feed comment' }
          sender_name { 'Agent' }
        end

        from { channel[:options][:pages][0][:name] }
        to { ticket.customer.fullname }
        in_reply_to { "#{Faker::Number.number(digits: 16)}_#{Faker::Number.number(digits: 15)}" }

        preferences do
          {
            delivery_retry:          1,
            delivery_status_message: nil,
            delivery_status:         'success',
            delivery_status_date:    Time.current,
          }
        end
      end
    end
  end
end
