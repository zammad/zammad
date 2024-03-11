# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Message::Text, :aggregate_failures, current_user_id: 1 do
  subject(:message) { described_class.new(data:, channel:) }

  let(:channel)    { create(:whatsapp_channel) }
  let(:timestamp)  { Time.zone.now.change(usec: 0) } # omit milliseconds
  let(:message_id) { 'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA' }

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
              id:        message_id,
              timestamp: timestamp.to_i,
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

  context 'when an initial incoming message is received' do
    before do
      message.process
    end

    it 'schedules a reminder job for 23 hours in the future' do
      expect(Ticket.last.preferences).to include(
        whatsapp: include(
          last_reminder_job_id: Delayed::Job.last.id,
        ),
      )
      expect(Delayed::Job.last).to have_attributes(run_at: timestamp + 23.hours)
    end
  end

  context 'when an additional incoming message is received' do
    let(:article)  { create(:whatsapp_article, ticket: ticket) }
    let(:ticket)   { create(:whatsapp_ticket, channel: channel, customer: customer) }
    let(:customer) { create(:customer, mobile: "+#{from[:phone]}") }
    let(:job_id)   { ScheduledWhatsappReminderJob.perform_at(Time.zone.now, ticket, Locale.default).provider_job_id }

    before do
      travel_to 12.hours.ago
      article
      preferences = ticket.preferences
      preferences[:whatsapp][:last_reminder_job_id] = job_id
      ticket.update!(preferences:)
      travel_back
      message.process
    end

    it 'cancels the last reminder job' do
      expect(Delayed::Job.exists?(job_id)).to be(false)
    end

    it 'schedules a new reminder job for 23 hours in the future' do
      expect(ticket.reload.preferences).to include(
        whatsapp: include(
          last_reminder_job_id: Delayed::Job.last.id,
        ),
      )
      expect(Delayed::Job.last).to have_attributes(run_at: timestamp + 23.hours)
    end
  end

  context 'when automatic reminders are turned off' do
    let(:channel) { create(:whatsapp_channel, reminder_active: false) }

    before do
      message.process
    end

    it 'does not schedule a reminder job' do
      expect(Ticket.last.preferences).to include(
        whatsapp: not_include(
          last_reminder_offset: 23.hours,
        ),
      )
    end
  end
end
