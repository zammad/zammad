# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Schedules a backgrond communication job for new email articles.
module Ticket::Article::EnqueueCommunicateEmailJob
  extend ActiveSupport::Concern

  included do
    after_create :ticket_article_enqueue_communicate_email_job
  end

  private

  def ticket_article_enqueue_communicate_email_job

    # return if we run import mode
    return true if Setting.get('import_mode')

    # only do send email if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return true if ApplicationHandleInfo.postmaster?

    # if sender is customer, do not communicate
    return true if !sender_id

    sender = Ticket::Article::Sender.lookup(id: sender_id)
    return true if sender.nil?
    return true if sender.name == 'Customer'

    # only apply on emails
    return true if !type_id

    type = Ticket::Article::Type.lookup(id: type_id)
    return true if type.nil?
    return true if type.name != 'email'

    # send background job
    TicketArticleCommunicateEmailJob.perform_later(id)
  end
end
