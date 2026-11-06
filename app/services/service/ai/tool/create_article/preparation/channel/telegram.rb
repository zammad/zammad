# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::CreateArticle::Preparation::Channel::Telegram < Service::AI::Tool::CreateArticle::Preparation::Channel
  delivers 'telegram personal-message', area: 'Telegram::Bot', label: 'Telegram', text_limit: 4096

  # A Telegram ticket names its bot, whose channel may be another than the ticket's.
  def self.of(ticket)
    TelegramHelper.bot_by_bot_id(ticket.preferences.dig('telegram', 'bid')) || super
  end

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  def prepare
    invalid('The Telegram channel has no API token.') if channel.options['api_token'].blank?
    destination = ticket.preferences.dig('telegram', 'chat_id')
    invalid('The ticket has no Telegram chat destination.') if destination.blank?
    data[:to] = destination.to_s
    data[:from] = channel.options.dig('bot', 'username').to_s
  end
end
