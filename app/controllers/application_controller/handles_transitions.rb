# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::HandlesTransitions
  extend ActiveSupport::Concern

  included do
    around_action :handle_transaction
  end

  private

  def handle_transaction
    ApplicationHandleInfo.current = 'application_server'
    PushMessages.init

    yield

    TransactionDispatcher.commit(transaction_dispatch_options)
    PushMessages.finish
  ensure
    ApplicationHandleInfo.current = nil
  end

  def transaction_dispatch_options
    return {} if !current_user&.permissions?(%w[ticket.agent admin])
    return {} if !request.headers['X-Zammad-Suppress-Notifications'].to_s.casecmp?('true')

    { disable_notification: true }
  end
end
