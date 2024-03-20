# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Location < Whatsapp::Webhook::Message
  OSM_MARKER_URL = 'https://www.openstreetmap.org/?mlat=%s&mlon=%s#map=17/%s/%s'.freeze

  private

  def body
    "📍 <a href='#{format(OSM_MARKER_URL, message[:latitude], message[:longitude], message[:latitude], message[:longitude])}' target='_blank'>#{message[:name] || 'Location'}</a>"
  end

  def content_type
    'text/html'
  end

  def type
    :location
  end
end
