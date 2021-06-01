# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasTransactionDispatcher
  extend ActiveSupport::Concern

  included do
    after_create  TransactionDispatcher
    before_update TransactionDispatcher
  end

end
