# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

    TransactionDispatcher.commit
    PushMessages.finish
    ActiveSupport::Dependencies::Reference.clear!
  ensure
    ApplicationHandleInfo.current = nil
  end
end
