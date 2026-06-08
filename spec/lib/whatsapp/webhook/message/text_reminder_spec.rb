# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Message::Text, current_user_id: 1 do
  let(:channel)    { create(:whatsapp_channel) }
  let(:jobs_scope) { Delayed::Job.where("handler LIKE '%job_class: ScheduledWhatsappReminderJob%'") }

  let(:from) do
    {
      phone: Faker::PhoneNumber.cell_phone_in_e164.delete('+'),
      name:  Faker::Name.unique.name,
    }
  end

  def build_message(timestamp: Time.zone.now.at_beginning_of_minute, message_id: "wamid.#{SecureRandom.uuid}")
    described_class.new(
      data:    {
        entry: [{
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
      },
      channel: channel,
    )
  end

  context 'when an initial incoming message is received' do
    let(:timestamp) { Time.current.at_beginning_of_minute }

    before do
      build_message.process
    end

    it 'schedules a reminder job for 23 hours in the future' do
      expect(jobs_scope.last).to have_attributes(run_at: timestamp + 23.hours)
    end

    it 'schedules a job with the correct arguments' do
      job    = Delayed::Job.last
      ticket = Ticket.last

      expect(job.payload_object.job_data).to include(
        'arguments' => [{ '_aj_globalid'=> ticket.to_gid.to_s }, 'en-us']
      )
    end
  end

  context 'when an additional incoming message is received' do
    let(:ticket)   { create(:whatsapp_ticket, channel: channel, customer: customer) }
    let(:customer) { create(:customer, mobile: "+#{from[:phone]}") }

    before do
      travel_to 12.hours.ago
      build_message.process
      travel_back
    end

    it 'does not add an additional reminder job' do
      expect { build_message.process }
        .not_to change(jobs_scope, :count)
    end

    it 'delays existing reminder job for 23 hours in the future' do
      timestamp = Time.current.at_beginning_of_minute
      expect { build_message(timestamp:).process }
        .to change { jobs_scope.sole.reload.run_at }
        .to(timestamp + 23.hours)
    end
  end

  context 'when automatic reminders are turned off' do
    let(:channel) { create(:whatsapp_channel, reminder_active: false) }

    before do
      build_message.process
    end

    it 'does not schedule a reminder job' do
      expect { build_message.process }
        .not_to change(jobs_scope, :count)
    end
  end
end
