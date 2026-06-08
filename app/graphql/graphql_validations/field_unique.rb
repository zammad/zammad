# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module GraphqlValidations
  module FieldUnique
    def initialize(*)
      super

      @field_unique_names = Set.new
    end

    def on_field(node, parent)
      if parent != @field_unique_last_parent
        @field_unique_last_parent = parent
        @field_unique_names.clear
      end

      name = node.alias || node.name

      if @field_unique_names.include?(name)
        raise GraphqlValidations::Error, "Field '#{node.name}' is duplicated in the same selection set"
      end

      @field_unique_names << name

      super
    end

  end
end
