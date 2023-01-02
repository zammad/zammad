# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module HasTransactionDispatcher
  extend ActiveSupport::Concern

  included do
    after_create  TransactionDispatcher
    before_update TransactionDispatcher
  end

end
