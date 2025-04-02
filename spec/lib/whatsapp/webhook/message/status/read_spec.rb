# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Message::Status::Read, :aggregate_failures, current_user_id: 1 do
  describe '#process' do
    let(:channel) { create(:whatsapp_channel) }

    let(:from) do
      {
        phone: Faker::PhoneNumber.cell_phone_in_e164.delete('+'),
        name:  Faker::Name.unique.name,
      }
    end

    let(:json) do
      {
        object: 'whatsapp_business_account',
        entry:  [
          {
            id:      '260895230431646',
            changes: [
              {
                value: {
                  messaging_product: 'whatsapp',
                  metadata:          {
                    display_phone_number: '15551340563',
                    phone_number_id:      channel.options[:phone_number_id],
                  },
                  statuses:          [
                    {
                      id:           message_id,
                      status:       'read',
                      timestamp:    '1709577872',
                      recipient_id: '15551340563',
                      conversation: {
                        id:     '2f3568fab8879aa0194e66aac1a0618e',
                        origin: {
                          type: 'service'
                        }
                      },
                      pricing:      {
                        billable:      true,
                        pricing_model: 'CBP',
                        category:      'service'
                      }
                    }
                  ]
                },
                field: 'messages'
              }
            ]
          }
        ]
      }.to_json
    end

    let(:data) { JSON.parse(json).deep_symbolize_keys }

    let(:article) { create(:whatsapp_article, :inbound, ticket: ticket) }
    let(:ticket)  { create(:whatsapp_ticket, channel: channel) }

    let(:message_id) { article.message_id }

    context 'when all data is valid' do
      before { article }

      it 'updates the ticket and article preferences accordingly' do
        described_class.new(data:, channel:).process

        expect(Ticket::Article.last.preferences).to include(
          whatsapp: include(
            timestamp_read: '1709577872',
          ),
        )
      end
    end

    context 'when no related article exists' do
      before { article }

      let(:message_id) { "wamid.#{Faker::Number.unique.number}" }

      it 'raises an error' do
        expect { described_class.new(data:, channel:).process }
          .to raise_error(
            an_instance_of(Whatsapp::Webhook::Payload::ProcessableError)
            .and(
              having_attributes(
                reason: 'No related article found to process the status message on.'
              )
            )
          )
      end
    end
  end
end
