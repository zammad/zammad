# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Schedules a backgrond communication job for new telegram articles.
module Ticket::Article::EnqueueCommunicateTelegramJob
  extend ActiveSupport::Concern

  included do
    after_create :ticket_article_enqueue_communicate_telegram_job
  end

  private

  def ticket_article_enqueue_communicate_telegram_job

    # return if we run import mode
    return true if Setting.get('import_mode')

    # if sender is customer, do not communicate
    return true if !sender_id

    sender = Ticket::Article::Sender.lookup(id: sender_id)
    return true if sender.nil?
    return true if sender.name == 'Customer'

    # only apply on telegram messages
    return true if !type_id

    type = Ticket::Article::Type.lookup(id: type_id)
    return true if !type.name.match?(%r{\Atelegram}i)

    CommunicateTelegramJob.perform_later(id)
  end

end
