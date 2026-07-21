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

    # Registered as a callable because authentication has not run yet at this
    # point - current_user is only available once a commit actually happens.
    TransactionDispatcher.request_options = -> { transaction_dispatch_options }

    yield
  ensure
    TransactionDispatcher.commit
    PushMessages.finish

    TransactionDispatcher.request_options = nil
    ApplicationHandleInfo.current = nil
    UserInfo.reset
  end

  def transaction_dispatch_options
    return {} if !current_user&.permissions?(%w[ticket.agent admin])
    return {} if !request.headers['X-Zammad-Suppress-Notifications'].to_s.casecmp?('true')

    { disable_notification: true }
  end
end
