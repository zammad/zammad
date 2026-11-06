# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::CreateArticle::Preparation::Channel::WhatsApp < Service::AI::Tool::CreateArticle::Preparation::Channel
  delivers 'whatsapp message', area: 'WhatsApp::Business', label: 'WhatsApp', text_limit: 4096

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  def prepare
    invalid('The WhatsApp channel is not configured.') if channel.options['adapter'] != 'whatsapp'
    check_window
    destination = ticket.preferences.dig('whatsapp', 'from', 'phone_number')
    invalid('The ticket has no WhatsApp recipient.') if destination.blank?
    data[:to] = destination.to_s
    data[:from] = channel.options['phone_number'].to_s
  end

  private

  def check_window
    timestamp = Integer(ticket.preferences.dig('whatsapp', 'timestamp_incoming'), exception: false)
    invalid('The WhatsApp reply window cannot be determined from this ticket.') if !timestamp
    invalid('WhatsApp replies are unavailable on closed tickets.') if %w[closed merged removed].include?(ticket.state.name)
    invalid('The WhatsApp 24-hour reply window is closed. Wait for a new customer message.') if Time.zone.at(timestamp) <= 24.hours.ago
  end
  # rubocop:enable Zammad/DetectTranslatableString
end
