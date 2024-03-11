# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Location < Whatsapp::Webhook::Message
  private

  def body
    "📍 <a href='https://www.google.com/maps/search/?api=1&query=#{message[:latitude]},#{message[:longitude]}' target='_blank'>#{message[:name] || 'Location'}</a>"
  end

  def content_type
    'text/html'
  end

  def type
    :location
  end
end
