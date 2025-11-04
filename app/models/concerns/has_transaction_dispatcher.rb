# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module HasTransactionDispatcher
  extend ActiveSupport::Concern

  included do
    class_attribute :transaction_ignore_changes_attributes_list, default: []

    after_create TransactionDispatcher
    after_update TransactionDispatcher
  end

  class_methods do
    def transaction_ignore_changes_attributes(*attributes)
      self.transaction_ignore_changes_attributes_list = attributes
    end
  end

  def transaction_ignore_changes_attributes
    transaction_ignore_changes_attributes_list
  end
end
