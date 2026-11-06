# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::CreateArticle::Preparation::Channel::Sms < Service::AI::Tool::CreateArticle::Preparation::Channel
  delivers 'sms', area: 'Sms::Account', label: 'SMS', text_limit: 160

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  class << self
    def check(ticket:, arguments:)
      super
      invalid('The ticket is not an SMS ticket.') if ticket.create_article_type&.name != 'sms'
    end

    # An SMS goes to the one number the caller names, which the ticket does not hold.
    def recipient(arguments)
      recipients = Array(arguments[:to])
      invalid('SMS requires exactly one explicit recipient phone number.') if recipients.size != 1 || !recipients.first.match?(%r{\A\+?[0-9]{5,20}\z})

      recipients.first
    end
  end

  def prepare
    invalid('The SMS channel is not configured.') if !channel.options&.dig('adapter')&.start_with?('sms/')
    data[:to] = self.class.recipient(arguments)
    data[:from] = channel.options['sender']
  end
  # rubocop:enable Zammad/DetectTranslatableString
end
