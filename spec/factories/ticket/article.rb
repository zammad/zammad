# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'ticket/article', aliases: %i[ticket_article] do
    inbound_email

    ticket factory: :ticket, strategy: :create # or else build(:ticket_article).save fails
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

      ticket factory: %i[twitter_ticket]
      subject      { nil }
      body         { Faker::Lorem.sentence }
      content_type { 'text/plain' }
      message_id   { Faker::Number.unique.number(digits: 18) }

      after(:create) do |article, context|
        next if context.sender_name == 'Agent'

        context.ticket.title = article.body

        context.ticket.save!
      end

      trait :inbound do
        transient do
          sender_name  { 'Customer' }
          username     { Faker::Twitter.screen_name }
          sender_id    { Faker::Number.unique.number(digits: 18) }
          recipient_id { Faker::Number.unique.number(digits: 19) }
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
          sender_id    { Faker::Number.unique.number(digits: 18) }
          recipient_id { Faker::Number.unique.number(digits: 19) }
        end

        from        { "@#{ticket.preferences['channel_screen_name']}" }
        to          { "@#{username}" }
        body        { "#{to} #{Faker::Lorem.sentence}" }
        in_reply_to { Faker::Number.unique.number(digits: 19) }

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
        in_reply_to { Faker::Number.unique.number(digits: 19) }
      end
    end

    factory :twitter_dm_article do
      transient do
        type_name { 'twitter direct-message' }
      end

      ticket factory: %i[twitter_ticket]
      body { Faker::Lorem.sentence }

      trait :pending_delivery do
        transient do
          recipient { association :twitter_authorization }
          sender_id { Faker::Number.unique.number(digits: 10) }
        end

        from         { ticket.owner.fullname }
        to           { recipient.username }
        in_reply_to  { Faker::Number.unique.number(digits: 19) }
        content_type { 'text/plain' }
      end

      trait :delivered do
        pending_delivery
        message_id { Faker::Number.unique.number(digits: 19) }
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

      ticket factory: %i[sms_ticket]
      from { Faker::PhoneNumber.cell_phone_in_e164 }
      to   { Faker::PhoneNumber.cell_phone_in_e164 }
      subject { nil }
      body { Faker::Lorem.sentence }
      message_id { Faker::Number.unique.number(digits: 19) }
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

        in_reply_to { Faker::Number.unique.number(digits: 19) }

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

    factory :whatsapp_article do
      inbound

      transient do
        type_name          { 'whatsapp message' }
        channel            { Channel.find(ticket.preferences[:channel_id]) }
        from_phone_number  { Faker::PhoneNumber.cell_phone_in_e164 }
        from_name          { Faker::Name.unique.name }
        timestamp_incoming { Time.zone.now.to_i.to_s }
      end

      ticket factory: %i[whatsapp_ticket]
      to { "#{channel.options[:name]} (#{channel.options[:phone_number]})" }
      subject { nil }
      body { Faker::Lorem.sentence }
      content_type { 'text/plain' }

      before(:create) do |_article, context|
        next if context.sender_name == 'Agent' && context.ticket.preferences[:whatsapp].present?

        context.ticket.preferences.tap do |p|
          p['whatsapp'] = {
            from:               {
              phone_number: context.from_phone_number.delete('+'),
              display_name: context.from_name,
            },
            timestamp_incoming: context.timestamp_incoming,
          }
        end
        context.ticket.title = "New WhatsApp message from #{context.from_name} (#{context.from_phone_number})"
        context.ticket.save!
      end

      trait :inbound do
        transient do
          sender_name { 'Customer' }
        end

        message_id { "wamid.#{Faker::Number.unique.number}" }
        from { "#{from_name} (#{from_phone_number})" }
        created_by_id { ticket.customer_id } # NB: influences the value for the from field!

        preferences do
          {
            whatsapp: {
              entry_id:   channel[:options][:phone_number_id],
              message_id: message_id,
            }
          }
        end
      end

      trait :pending_delivery do
        transient do
          sender_name { 'Agent' }
        end

        preferences { {} }

        created_by_id { create(:agent).id } # NB: influences the value for the from field!
        in_reply_to { "wamid.#{Faker::Number.unique.number}" }
      end

      trait :outbound do
        pending_delivery

        message_id { "wamid.#{Faker::Number.unique.number}" }

        preferences do
          {
            delivery_retry:          1,
            whatsapp:                {
              message_id:,
            },
            delivery_status_message: nil,
            delivery_status:         'success',
            delivery_status_date:    Time.current,
          }
        end
      end

      trait :with_attachment_media_document do
        after(:create) do |article, _context|
          create(:store,
                 object:      article.class.name,
                 o_id:        article.id,
                 data:        Faker::Lorem.unique.sentence,
                 filename:    'test.txt',
                 preferences: { 'Content-Type' => 'text/plain' })

          article.preferences.tap do |prefs|
            prefs['whatsapp'] = {
              entry_id:   Faker::Number.unique.number.to_s,
              message_id: "wamid.#{Faker::Number.unique.number}",
              type:       'document',
              media_id:   Faker::Number.unique.number.to_s
            }
          end
          article.save!
        end
      end

      trait :with_media_error do
        after(:create) do |article, _context|
          article.preferences.tap do |prefs|
            prefs['whatsapp'] = {
              entry_id:    Faker::Number.unique.number.to_s,
              message_id:  "wamid.#{Faker::Number.unique.number}",
              type:        'document',
              media_id:    Faker::Number.unique.number.to_s,
              media_error: true,
            }
          end
          article.save!
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

      ticket factory: %i[telegram_ticket]
      to { "@#{channel[:options][:bot][:username]}" }
      subject { nil }
      body { Faker::Lorem.sentence }
      message_id { "#{Faker::Number.unique.decimal(l_digits: 1, r_digits: 10)}@telegram" }
      content_type { 'text/plain' }

      after(:create) do |article, context|
        next if context.sender_name == 'Agent'

        context.ticket.title = article.body
        context.ticket.preferences.tap do |p|
          p['telegram'] = {
            bid:     context.channel[:options][:bot][:id],
            chat_id: (article.preferences[:telegram] && article.preferences[:telegram][:chat_id]) || Faker::Number.unique.number(digits: 10),
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
                'id'            => Faker::Number.unique.number,
                'is_bot'        => false,
                'first_name'    => Faker::Name.unique.first_name,
                'last_name'     => Faker::Name.unique.last_name,
                'username'      => username,
                'language_code' => 'en',
              ),
            },
            update_id: Faker::Number.unique.number(digits: 8),
          }
        end
      end

      trait :outbound do
        transient do
          sender_name { 'Agent' }
        end

        to { "@#{username}" }
        created_by_id { create(:agent).id } # NB: influences the value for the from field!
        in_reply_to { "#{Faker::Number.unique.decimal(l_digits: 1, r_digits: 10)}@telegram" }

        preferences do
          {
            delivery_retry:          1,
            telegram:                {
              date:       Time.current.to_i,
              from_id:    Faker::Number.unique.number(digits: 10),
              chat_id:    Faker::Number.unique.number(digits: 10),
              message_id: Faker::Number.unique.number,
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
        post_id { Faker::Number.unique.number(digits: 15) }
        permalink_url { "https://www.facebook.com/#{channel[:options][:pages][0][:id]}/posts/#{post_id}/?comment_id=#{post_id}" }
      end

      ticket factory: %i[facebook_ticket]
      subject { nil }
      body { Faker::Lorem.sentence }
      message_id { "#{Faker::Number.unique.number(digits: 16)}_#{Faker::Number.unique.number(digits: 15)}" }
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
        in_reply_to { "#{Faker::Number.unique.number(digits: 16)}_#{Faker::Number.unique.number(digits: 15)}" }

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

    trait :with_attachment do
      transient do
        attachment { File.open('spec/fixtures/files/upload/hello_world.txt') }
      end

      after(:create) do |article, context|
        create(:store,
               object:      article.class.name,
               o_id:        article.id,
               data:        context.attachment.read,
               filename:    File.basename(context.attachment.path),
               preferences: {})
      end
    end

    trait :with_prepended_attachment do
      transient do
        attachment            { File.open('spec/fixtures/files/upload/hello_world.txt') }
        override_content_type { nil }
        attachments_count     { 1 }
      end

      after(:build) do |article, context|
        filename     = File.basename(context.attachment.path)
        content_type = context.override_content_type || MIME::Types.type_for(filename).first&.content_type

        attachments = []

        context.attachments_count.times do
          attachments << create(:store,
                                data:        context.attachment.read,
                                filename:    filename,
                                preferences: { 'Content-Type' => content_type })
        end

        article.attachments = attachments
      end
    end

  end
end
