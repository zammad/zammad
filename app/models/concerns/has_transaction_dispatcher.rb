# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module HasTransactionDispatcher
  extend ActiveSupport::Concern

  included do
    after_create  TransactionDispatcher
    before_update TransactionDispatcher
  end

end
