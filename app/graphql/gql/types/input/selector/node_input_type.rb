# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Selector
  class NodeInputType < Gql::Types::BaseInputObject
    MAX_NESTING_DEPTH = 4
    MAX_NODES         = 250

    description 'Selector node: either a single condition (name/operator/value) or a subclause (operator/conditions).'

    argument :operator, String, description: 'Block operator (AND/OR/NOT) for subclauses or the condition operator (e.g. "is", "contains") for single conditions.'

    argument :conditions, [self], required: false, description: 'Nested conditions, present on subclauses only.'

    argument :name, String, required: false, description: 'Target attribute, e.g. "ticket.title", conditions only.'
    argument :value, GraphQL::Types::JSON, required: false, description: 'Condition value (primitive or array), conditions only.'
    argument :pre_condition, String, required: false, description: 'Optional pre-condition (e.g. "current_user.id", "not_set"), conditions only.'
    argument :range, String, required: false, description: 'Optional range unit for relative time operators (e.g. "minute", "day"), conditions only.'

    def prepare
      hash = super.to_h
      validate_node!(hash)
      transform_value(hash)
      hash
    end

    private

    def validate_node!(hash, depth: 1, node_count: 0)
      raise GraphQL::ExecutionError, __('Selector exceeded maximum nesting depth.') if depth > MAX_NESTING_DEPTH

      node_count += 1

      raise GraphQL::ExecutionError, __('Selector exceeded maximum number of nodes.') if node_count > MAX_NODES

      validate_shape!(hash)
      return node_count if hash[:conditions].blank?

      hash[:conditions].reduce(node_count) do |memo, elem|
        validate_node!(elem, depth: depth + 1, node_count: memo)
      end
    end

    def validate_shape!(hash)
      subclause = hash.key?(:conditions)
      condition = hash.key?(:name)
      operator  = hash[:operator]

      if subclause == condition
        raise GraphQL::ExecutionError, __('Selector node must be either a subclause (operator + conditions) or a single condition.')
      elsif subclause
        validate_subclause!(operator)
      elsif condition
        validate_condition!(operator)
      end
    end

    def validate_subclause!(operator)
      return if ::Selector::Sql.valid_block_operator?(operator)

      raise GraphQL::ExecutionError, "Invalid block operator: #{operator.inspect}."
    end

    def validate_condition!(operator)
      return if ::Selector::Sql.valid_operator?(operator)

      raise GraphQL::ExecutionError, "Invalid condition operator: #{operator.inspect}."
    end

    def transform_value(hash)
      return if hash[:name] != 'ticket.tags' || hash[:operator] != 'contains one'
      return if !hash[:value].is_a?(Array)

      # Although the frontend sends tag values as arrays, the backend expects a comma-separated string for the
      #   `contains one` operator. This string is later split back into an array in corresponding search backend.
      hash[:value] = hash[:value].join(', ')
    end
  end
end
