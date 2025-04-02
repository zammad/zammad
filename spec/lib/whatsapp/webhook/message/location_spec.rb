# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Message::Location, :aggregate_failures, current_user_id: 1 do
  describe '#process' do
    let(:channel)       { create(:whatsapp_channel, welcome: 'Hey there!') }
    let(:location_name) { 'Langenbach Arena' }

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
                location:  {
                  latitude:  50.697254180908,
                  longitude: 7.9327116012573,
                  name:      location_name,
                  url:       'https://foursquare.com/v/4fddbd3ee4b06434e8dc7504'
                },
                type:      'location',
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

        expect(Ticket::Article.second_to_last.body).to include('Langenbach Arena')
          .and include('https://www.openstreetmap.org')
          .and include('50.697254180908')
          .and include('7.9327116012573')

        expect(Ticket::Article.second_to_last).to have_attributes(
          content_type: 'text/html',
        )
        expect(Ticket::Article.second_to_last.preferences).to include(
          whatsapp: {
            entry_id:   '222259550976437',
            message_id: 'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA',
            type:       'location',
          }
        )

        # Welcome article
        expect(Ticket::Article.last).to have_attributes(
          body:         'Hey there!',
          content_type: 'text/plain',
        )
      end

      context 'when location has no name set' do
        let(:location_name) { nil }

        it 'uses fallback text for the link' do
          described_class.new(data:, channel:).process

          expect(Ticket::Article.second_to_last.body).to include('Location')
            .and include('target="_blank"')
        end
      end
    end
  end
end
