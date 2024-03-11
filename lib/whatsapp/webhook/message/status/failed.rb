# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Status::Failed < Whatsapp::Webhook::Message::Status
  private

  def create_article?
    true
  end

  def update_related_article?
    true
  end

  def update_related_article_attributes
    status_message = "#{error[:title]} (#{error[:code]})"
    if error.dig(:error_data, :details).present?
      status_message = error.dig(:error_data, :details)
    end

    preferences = @related_article.preferences
    preferences[:whatsapp][:delivery_status]         = 'fail'
    preferences[:whatsapp][:delivery_status_date]    = Time.zone.now
    preferences[:whatsapp][:delivery_status_message] = status_message

    { preferences: }
  end

  def body
    body = "#{error[:title]} (#{error[:code]})"

    if error.dig(:error_data, :details).present?
      body = "#{body}\n\n#{error.dig(:error_data, :details)}"
    end

    if error[:href].present?
      body = "#{body}\n\n#{error[:href]}"
    end

    handle_error

    body
  end

  def error
    @error = status[:errors].first
  end

  def handle_error
    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes
    #
    # Log any error status to the Rails log. Update the channel status on
    # any unrecoverable error - errors that need action from an administator
    # and block the channel from sending or receiving messages.

    Rails.logger.error "WhatsApp channel (#{@channel.options[:callback_url_uuid]}) - failed status message: #{error[:title]} (#{error[:code]})"

    recoverable_errors = [
      130_472, # User's number is part of an experiment'
      131_021, # Recipient cannot be sender'
      131_026, # Message undeliverable'
      131_047, # Re-engagement message
      131_052, # Media download error'
      131_053  # Media upload error'
    ]
    return if recoverable_errors.include?(error[:code])

    @channel.update!(
      status_out:   'error',
      last_log_out: "#{error[:title]} (#{error[:code]})",
    )
  end
end
