# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ScheduledWhatsappReminderJob, type: :job do
  let(:channel)       { create(:whatsapp_channel) }
  let(:ticket)        { create(:whatsapp_ticket, channel: channel) }
  let(:reminder_time) { 12.hours.from_now }
  let(:locale)        { Locale.default }

  describe '#perform_at' do
    it 'schedules ticket unique delayed job at appointed time' do
      expect(described_class.perform_at(reminder_time, ticket, locale))
        .to have_attributes(
          arguments:    [ticket, locale],
          lock_key:     "ScheduledWhatsappReminderJob/#{ticket.id}",
          scheduled_at: reminder_time.to_f,
        )
    end
  end

  describe '.perform' do
    subject(:job) { described_class.new(reminder_time, ticket, locale) }

    let(:article) { create(:whatsapp_article, ticket: ticket) }

    before do
      article
    end

    it 'adds a reminder article to the ticket' do
      expect(job.perform(ticket, locale)).to have_attributes(
        ticket_id:    ticket.id,
        type_id:      Ticket::Article::Type.lookup(name: 'whatsapp message').id,
        sender_id:    Ticket::Article::Sender.lookup(name: 'System').id,
        from:         "#{channel.options[:name]} (#{channel.options[:phone_number]})",
        to:           article.from,
        subject:      described_class::REMINDER_TEMPLATE.truncate(100, omission: '…'),
        internal:     false,
        body:         described_class::REMINDER_TEMPLATE,
        content_type: 'text/plain',
      )
    end

    context 'with locale other than default' do
      let(:locale) { 'de-de' }
      let(:source) { 'Hello, the customer service window for this conversation is about to expire, please reply to keep it open.' }
      let(:target) { "[translated] #{source}" }

      before do
        allow(Translation).to receive(:translate).with(locale, source).and_return(target)
      end

      it 'translates the reminder text' do
        expect(job.perform(ticket, locale)).to have_attributes(
          subject: target.truncate(100, omission: '…'),
          body:    target,
        )
      end
    end

    context 'when automatic reminders are turned off' do
      let(:channel) { create(:whatsapp_channel, reminder_active: false) }

      it 'skips the reminder article' do
        expect(job.perform(ticket, locale)).to be_falsey
      end
    end

    context 'with another channel' do
      let(:channel) { create(:facebook_channel) }

      it 'skips the reminder article' do
        expect(job.perform(ticket, locale)).to be_falsey
      end
    end

    context 'with closed ticket' do
      let(:ticket) { create(:whatsapp_ticket, channel: channel, state: Ticket::State.find_by(name: 'closed')) }

      it 'skips the reminder article' do
        expect(job.perform(ticket, locale)).to be_falsey
      end
    end
  end
end
