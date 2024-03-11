# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ScheduledWhatsappReminderJob < ApplicationJob
  include HasActiveJobLock

  REMINDER_TEMPLATE = __('Hello, the customer service window for this conversation is about to expire, please reply to keep it open.').freeze

  def lock_key
    # "ScheduledWhatsappReminderJob/1"
    "#{self.class.name}/#{arguments[0].id}"
  end

  def self.perform_at(scheduled_time, ticket, locale)
    set(wait_until: scheduled_time).perform_later(ticket, locale)
  end

  def perform(ticket, locale)
    channel = Channel.find_by(id: ticket.preferences[:channel_id], area: 'WhatsApp::Business')
    return if channel.nil? || !channel.options[:reminder_active]

    # Do not run for closed tickets.
    return if Ticket::State.where(name: %w[closed merged removed]).pluck(:id).include?(ticket.state_id)

    profile_name = ticket.preferences.dig(:whatsapp, :from, :display_name)
    phone_number = ticket.preferences.dig(:whatsapp, :from, :phone_number)

    translated_reminder_message = Translation.translate(locale, REMINDER_TEMPLATE)

    UserInfo.with_user_id(1) do
      Ticket::Article.create!(
        ticket_id:    ticket.id,
        type_id:      Ticket::Article::Type.lookup(name: 'whatsapp message').id,
        sender_id:    Ticket::Article::Sender.lookup(name: 'System').id,
        from:         "#{channel.options[:name]} (#{channel.options[:phone_number]})",
        to:           "#{profile_name} (#{phone_number})",
        subject:      translated_reminder_message.truncate(100, omission: '…'),
        internal:     false,
        body:         translated_reminder_message,
        content_type: 'text/plain',
      )
    end
  end
end
