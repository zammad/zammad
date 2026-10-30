# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Message::Text, :aggregate_failures, current_user_id: 1 do
  describe '#process' do
    let(:channel) { create(:whatsapp_channel, welcome: 'W' * 120) }

    let(:from) do
      {
        phone: Faker::PhoneNumber.cell_phone_in_e164.delete('+'),
        name:  Faker::Name.unique.name,
      }
    end

    let(:json) do
      {
        object: 'whatsapp_business_account',
        entry:  [{
          id:      '222259550976437',
          changes: [{
            value: {
              messaging_product: 'whatsapp',
              metadata:          {
                display_phone_number: '15551340563',
                phone_number_id:      channel.options[:phone_number_id],
              },
              contacts:          [{
                profile: {
                  name: from[:name],
                },
                wa_id:   from[:phone],
              }],
              messages:          [{
                from:      from[:phone],
                id:        'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA',
                timestamp: '1707921703',
                text:      {
                  body: 'Hello, world!',
                },
                type:      'text',
              }],
            },
            field: 'messages',
          }],
        }],
      }.to_json
    end

    let(:data) { JSON.parse(json).deep_symbolize_keys }

    context 'when all data is valid' do
      it 'creates a user' do
        expect { described_class.new(data:, channel:).process }.to change(User, :count).by(1)
      end

      it 'creates a ticket + an article' do
        described_class.new(data:, channel:).process

        expect(Ticket.last).to have_attributes(
          title:    "#{from[:name]} (+#{from[:phone]}) via WhatsApp",
          group_id: channel.group_id,
        )
        expect(Ticket.last.preferences).to include(
          channel_id:   channel.id,
          channel_area: channel.area,
          whatsapp:     {
            from:               {
              phone_number: from[:phone],
              display_name: from[:name],
            },
            timestamp_incoming: '1707921703',
          },
        )

        expect(Ticket::Article.second_to_last).to have_attributes(
          body:         'Hello, world!',
          content_type: 'text/plain',
        )
        expect(Ticket::Article.second_to_last.preferences).to include(
          whatsapp: {
            entry_id:   '222259550976437',
            message_id: 'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA',
            type:       'text',
          }
        )

        # Welcome article
        expect(Ticket::Article.last).to have_attributes(
          # truncated subject
          subject:      "#{'W' * 99}…",
          body:         'W' * 120,
          content_type: 'text/plain',
        )
      end
    end
    context 'when only a BSUID is available' do
      let(:bsuid)    { "MY.#{Faker::Number.unique.number(digits: 15)}" }
      let(:username) { Faker::Internet.unique.username }

      let(:bsuid_json) do
        payload = JSON.parse(json)
        value   = payload['entry'][0]['changes'][0]['value']

        value['contacts'][0] = {
          'profile' => { 'name' => from[:name], 'username' => username },
          'user_id' => bsuid,
        }
        value['messages'][0].delete('from')
        value['messages'][0]['from_user_id'] = bsuid

        payload.to_json
      end

      let(:bsuid_data) { JSON.parse(bsuid_json).deep_symbolize_keys }

      def process(payload = bsuid_data)
        described_class.new(data: payload, channel:).process
      end

      def payload_for(user_id:, name: from[:name], user: username)
        JSON.parse(bsuid_json).tap do |payload|
          value = payload['entry'][0]['changes'][0]['value']
          value['contacts'][0] = { 'profile' => { 'name' => name, 'username' => user }, 'user_id' => user_id }
          value['messages'][0]['from_user_id'] = user_id
        end.to_json.then { |j| JSON.parse(j).deep_symbolize_keys }
      end

      it 'creates a user without phone number, identified by the BSUID' do
        expect { process }.to change(User, :count).by(1)

        user = Authorization.find_by(provider: 'whatsapp', uid: bsuid).user

        expect(user).to have_attributes(mobile: be_blank, login: bsuid)
        expect(user.fullname).to eq(from[:name])
      end

      it 'stores the username on the authorization and the ticket' do
        process

        expect(Authorization.find_by(provider: 'whatsapp', uid: bsuid)).to have_attributes(username:)
        expect(Ticket.last.preferences[:whatsapp][:from]).to include(user_id: bsuid, username:, display_name: from[:name], phone_number: nil)
      end

      it 'uses the username in the ticket title instead of a phone number' do
        process

        expect(Ticket.last.title).to eq("#{from[:name]} (#{username}) via WhatsApp")
      end

      it 'resolves repeated messages of the same BSUID to the same user and ticket' do
        process

        expect { process }.to not_change(User, :count).and not_change(Ticket, :count)
      end

      it 'treats the username as display information only' do
        process
        user = Authorization.find_by(provider: 'whatsapp', uid: bsuid).user

        expect { process(payload_for(user_id: bsuid, user: 'renamed.user')) }.to not_change(User, :count)

        expect(Authorization.find_by(provider: 'whatsapp', uid: bsuid)).to have_attributes(user_id: user.id, username: 'renamed.user')
      end

      it 'creates different users for different BSUIDs' do
        process

        expect { process(payload_for(user_id: "MY.#{Faker::Number.unique.number(digits: 15)}", user: username)) }
          .to change(User, :count).by(1)
      end

      it 'links the BSUID to an existing phone user and keeps the phone number' do
        process(data)

        phone_user = User.by_mobile(number: "+#{from[:phone]}")

        payload = JSON.parse(json).tap do |p|
          p['entry'][0]['changes'][0]['value']['messages'][0]['from_user_id'] = bsuid
        end

        expect { process(JSON.parse(payload.to_json).deep_symbolize_keys) }.to not_change(User, :count)
        expect(Authorization.find_by(provider: 'whatsapp', uid: bsuid).user).to eq(phone_user)
      end
    end

    context 'when a phone number is available' do
      it 'does not create an authorization and keeps the phone as login' do
        expect { described_class.new(data:, channel:).process }.to not_change(Authorization, :count)

        expect(User.by_mobile(number: "+#{from[:phone]}")).to have_attributes(login: from[:phone])
      end
    end
  end
end