# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Message::Status::Failed, :aggregate_failures, current_user_id: 1 do
  describe '#process' do
    let(:channel) { create(:whatsapp_channel) }

    let(:from) do
      {
        phone: Faker::PhoneNumber.cell_phone_in_e164.delete('+'),
        name:  Faker::Name.unique.name,
      }
    end

    let(:error_code) { 131_047 }

    let(:json) do
      {
        object: 'whatsapp_business_account',
        entry:  [
          {
            id:      '244742992051543',
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
                      status:       'failed',
                      timestamp:    '1708603746',
                      recipient_id: '15551340563',
                      errors:       [
                        {
                          code:       error_code,
                          title:      'Re-engagement message',
                          message:    'Re-engagement message',
                          error_data: {
                            details: 'Message failed to send because more than 24 hours have passed since the customer last replied to this number.'
                          },
                          href:       'https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/'
                        }
                      ]
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

      context 'with an recoverable error' do
        it 'creates an internal article with all error related information' do
          described_class.new(data:, channel:).process

          expect(Ticket::Article.last).to have_attributes(
            body:         "Unable to handle WhatsApp message: Re-engagement message (131047)\n\nMessage failed to send because more than 24 hours have passed since the customer last replied to this number.\n\nhttps://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/",
            content_type: 'text/plain',
            internal:     true,
          )

          expect(channel.reload).to have_attributes(
            status_out:   nil,
            last_log_out: nil,
          )
        end
      end

      context 'with an unrecoverable error' do
        let(:error_code) { 0 }

        it 'creates an internal article with all error related information and updates the channel as well' do
          described_class.new(data:, channel:).process

          expect(channel.reload).to have_attributes(
            status_out:   'error',
            last_log_out: 'Re-engagement message (0)',
          )
        end
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
