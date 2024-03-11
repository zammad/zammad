# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Payload, :aggregate_failures, current_user_id: 1 do
  let(:channel) { create(:whatsapp_channel) }

  let(:from) do
    {
      phone: Faker::PhoneNumber.cell_phone_in_e164.delete('+'),
      name:  Faker::Name.unique.name
    }
  end

  let(:user_data) do
    firstname, lastname = User.name_guess(from[:name])

    # Fallback to profile name if no firstname or lastname is found
    if firstname.blank? || lastname.blank?
      firstname, lastname = from[:name].split(%r{\s|\.|,|,\s}, 2)
    end

    {
      firstname: firstname&.strip,
      lastname:  lastname&.strip,
      mobile:    "+#{from[:phone]}",
      login:     from[:phone],
    }
  end

  let(:event)     { 'messages' }
  let(:type)      { 'text' }
  let(:timestamp) { '1707921703' }

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
              phone_number_id:      channel.options[:phone_number_id]
            },
            contacts:          [{
              profile: {
                name: from[:name]
              },
              wa_id:   from[:phone]
            }],
            messages:          [{
              from:      from[:phone],
              id:        'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA',
              timestamp: timestamp,
              text:      {
                body: 'Hello, world!'
              },
              type:      type
            }]
          },
          field: event
        }]
      }]
    }.to_json
  end

  let(:uuid) { channel.options[:callback_url_uuid] }

  let(:signature) do
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), channel.options[:app_secret], json)
  end

  describe '.new' do
    context 'when channel not exists' do
      let(:uuid) { 0 }

      it 'raises NoChannelError' do
        expect { described_class.new(json:, uuid:, signature:) }.to raise_error(Whatsapp::Webhook::NoChannelError)
      end
    end

    context 'when signatures do not match' do
      let(:signature) { 'foobar' }

      it 'raises ValidationError' do
        expect { described_class.new(json:, uuid:, signature:) }.to raise_error(described_class::ValidationError)
      end
    end

    context 'when signatures match' do
      it 'does not raise any error' do
        expect { described_class.new(json:, uuid:, signature:) }.not_to raise_error
      end
    end
  end

  describe '.process' do
    context 'when event is not messages' do
      let(:event) { 'foobar' }

      it 'raises ProcessableError' do
        expect { described_class.new(json:, uuid:, signature:).process }.to raise_error(described_class::ProcessableError)
      end
    end

    context 'when message has errors' do
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
                  phone_number_id:      channel.options[:phone_number_id]
                },
                contacts:          [{
                  profile: {
                    name: from[:name]
                  },
                  wa_id:   from[:phone]
                }],
                messages:          [{
                  from:      from[:phone],
                  id:        'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA',
                  timestamp: '1707921703',
                  text:      {
                    body: 'Hello, world!'
                  },
                  errors:    [
                    {
                      message:       '(#130429) Rate limit hit',
                      type:          'OAuthException',
                      code:          130_429,
                      error_data:    {
                        messaging_product: 'whatsapp',
                        details:           '<DETAILS>'
                      },
                      error_subcode: 2_494_055,
                      fbtrace_id:    'Az8or2yhqkZfEZ-_4Qn_Bam'
                    }
                  ],
                  type:      type
                }]
              },
              field: 'messages'
            }]
          }]
        }.to_json
      end

      it 'raises ProcessableError' do
        expect { described_class.new(json:, uuid:, signature:).process }.to raise_error(described_class::ProcessableError)
      end
    end

    context 'when an unsupported type is used' do
      let(:type)  { 'foobar' }

      it 'raises ProcessableError' do
        expect { described_class.new(json:, uuid:, signature:).process }.to raise_error(described_class::ProcessableError)
      end
    end

    context 'when everything is fine' do
      it 'does not raise any error' do
        expect { described_class.new(json:, uuid:, signature:).process }.not_to raise_error
      end

      context 'when no user exists' do
        it 'creates user' do
          described_class.new(json:, uuid:, signature:).process

          expect(User.last).to have_attributes(user_data)
        end
      end

      context 'when user already exists' do
        context 'when mobile is in common format with +' do
          before { create(:user, user_data) }

          it 'does not create a new user' do
            expect { described_class.new(json:, uuid:, signature:).process }.not_to change(User, :count)
          end
        end

        context 'when mobile is in e164 format' do
          before { create(:user, user_data).tap { |u| u.update!(mobile: u.mobile.delete('+')) } }

          it 'does not create a new user' do
            expect { described_class.new(json:, uuid:, signature:).process }.not_to change(User, :count)
          end
        end
      end

      context 'when no ticket exists' do
        it 'creates ticket' do
          expect { described_class.new(json:, uuid:, signature:).process }.to change(Ticket, :count).by(1)
        end

        it 'sets ticket preferences' do
          described_class.new(json:, uuid:, signature:).process

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
        end
      end

      context 'when ticket already exists' do
        let(:ticket_state) { 'open' }
        let(:timestamp)    { '1707921803' }

        let(:setup) do
          user = create(:user, user_data)
          create(:authorization, user: user, uid: user.mobile, provider: 'whatsapp_business')

          create(:ticket, customer: user, group_id: channel.group_id, state_id: Ticket::State.find_by(name: ticket_state).id, preferences: { channel_id: channel.id, channel_area: channel.area, whatsapp: { from: { phone_number: from[:phone], display_name: from[:name] }, timestamp_incoming: '1707921703' } })
        end

        before { setup }

        context 'when ticket is open' do
          it 'does not create a new ticket' do
            expect { described_class.new(json:, uuid:, signature:).process }.not_to change(Ticket, :count)
          end

          it 'updates the ticket preferences' do
            described_class.new(json:, uuid:, signature:).process

            expect(Ticket.last.preferences).to include(
              channel_id:   channel.id,
              channel_area: channel.area,
              whatsapp:     {
                from:               {
                  phone_number: from[:phone],
                  display_name: from[:name],
                },
                timestamp_incoming: '1707921803',
              },
            )
          end
        end

        context 'when ticket is closed' do
          let(:ticket_state) { 'closed' }

          it 'creates a new ticket' do
            expect { described_class.new(json:, uuid:, signature:).process }.to change(Ticket, :count).by(1)
          end
        end
      end
    end
  end

  describe '.process_status_message' do
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
                          code:       131_047,
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

    let(:article) { create(:whatsapp_article, :inbound, ticket: ticket) }
    let(:ticket)  { create(:whatsapp_ticket, channel: channel) }

    let(:message_id) { article.message_id }

    let(:uuid) { channel.options[:callback_url_uuid] }

    let(:signature) do
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), channel.options[:app_secret], json)
    end

    context 'when all data is valid' do
      it 'creates a new record in the HttpLog' do
        described_class.new(json:, uuid:, signature:).process

        expect(HttpLog.last).to have_attributes(
          direction: 'in',
          facility:  'WhatsApp::Business',
          url:       "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#{Rails.configuration.api_path}/channels_whatsapp_webhook/#{channel.options[:callback_url_uuid]}",
          status:    '200',
          request:   { content: JSON.parse(json).deep_symbolize_keys },
          response:  { content: {} },
          method:    'POST',
        )
      end
    end
  end
end
