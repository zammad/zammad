module ApplicationController::HandlesTransitions
  extend ActiveSupport::Concern

  included do
    before_action :transaction_begin
    after_action  :transaction_end
  end

  private

  def transaction_begin
    ApplicationHandleInfo.current = 'application_server'
    PushMessages.init
  end

  def transaction_end
    Observer::Transaction.commit
    PushMessages.finish
    ActiveSupport::Dependencies::Reference.clear!
  end
end
