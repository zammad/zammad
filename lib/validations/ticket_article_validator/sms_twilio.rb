# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Validations::TicketArticleValidator
  class SmsTwilio < Backend
    MATCHING_TYPES = ['sms'].freeze

    def validate_body
      return if @record.body.present?

      # Allow creation of the article for the unsupported message type (#5289):
      #  - no body
      #  - media present
      return if @record.preferences.dig('sms', 'NumMedia').to_i.positive?

      @record.errors.add :base, __('Body text is required')
    end

    private

    def validator_applies?
      channel_id = @record.preferences.dig('sms', 'channel_id')
      return false if channel_id.blank?

      channel = Channel.find(channel_id)
      return false if channel.blank?

      # Applicable only for SMS achannel of type Twilio.
      channel.options['adapter'] == 'sms/twilio'
    end
  end
end
