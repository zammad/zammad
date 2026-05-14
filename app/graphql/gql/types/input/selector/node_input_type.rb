# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Selector
  class NodeInputType < Gql::Types::BaseInputObject

    description 'Selector node: either a single condition (name/operator/value) or a subclause (operator/conditions).'

    argument :operator, String, description: 'Block operator (AND/OR/NOT) for subclauses or the condition operator (e.g. "is", "contains") for single conditions.'

    argument :conditions, [self], required: false, description: 'Nested conditions, present on subclauses only.'

    argument :name, String, required: false, description: 'Target attribute, e.g. "ticket.title", conditions only.'
    argument :value, GraphQL::Types::JSON, required: false, description: 'Condition value (primitive or array), conditions only.'
    argument :pre_condition, String, required: false, description: 'Optional pre-condition (e.g. "current_user.id", "not_set"), conditions only.'
    argument :range, String, required: false, description: 'Optional range unit for relative time operators (e.g. "minute", "day"), conditions only.'

    def prepare
      hash = super.to_h
      validate_shape!(hash)
      hash
    end

    private

    def validate_shape!(hash)
      subclause = hash.key?(:conditions)
      condition = hash.key?(:name)

      if subclause == condition
        raise GraphQL::ExecutionError, __('Selector node must be either a subclause (operator + conditions) or a single condition.')
      end

      operator = hash[:operator]

      if subclause
        raise GraphQL::ExecutionError, "Invalid block operator: #{operator.inspect}." if !::Selector::Sql.valid_block_operator?(operator)
      elsif !::Selector::Sql.valid_operator?(operator)
        raise GraphQL::ExecutionError, "Invalid condition operator: #{operator.inspect}."
      end
    end
  end
end
