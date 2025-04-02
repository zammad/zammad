# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Status::Failed < Whatsapp::Webhook::Message::Status
  include Whatsapp::Webhook::Concerns::HandlesError

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
    status[:errors].first
  end
end
