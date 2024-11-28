# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  extend ActiveSupport::Concern

  class_methods do
    def selectors(selectors, options = {})
      limit = options[:limit] || 10
      raise 'no selectors given' if !selectors

      query, bind_params, tables = selector2sql(selectors, options)
      return [] if !query

      ActiveRecord::Base.transaction(requires_new: true) do
        objects = distinct.where(query, *bind_params).joins(tables).reorder(options[:order_by])
        [objects.count, objects.limit(limit)]
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error e
        raise ActiveRecord::Rollback
      end
    end

    def selector2sql(selectors, options = {})
      Selector::Sql.new(selector: selectors, options: options, target_class: self).get
    end
  end
end
