# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CommunicateWhatsappJob < ApplicationJob

  retry_on Service::Ticket::Article::Type::TemporaryDeliveryError, attempts: 4, wait: lambda { |executions|
    executions * 120.seconds
  }

  def perform(article_id)
    whatsapp_message_deliver = Service::Ticket::Article::Type::WhatsappMessage::Deliver.new(article_id: article_id)
    whatsapp_message_deliver.execute
  end
end
