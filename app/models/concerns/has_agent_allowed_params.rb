# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasAgentAllowedParams
  extend ActiveSupport::Concern

  class_methods do
    def agent_allowed_params
      agent_allowed_attributes + agent_allowed_nested_relations
    end

    private

    def agent_allowed_attributes
      attrs = const_defined?(:AGENT_ALLOWED_ATTRIBUTES) ? const_get(:AGENT_ALLOWED_ATTRIBUTES) : []

      [:id] + attrs
    end

    def agent_allowed_nested_relations
      return [] if !const_defined?(:AGENT_ALLOWED_NESTED_RELATIONS)

      const_get(:AGENT_ALLOWED_NESTED_RELATIONS).map do |relation_identifier|
        key = :"#{relation_identifier}_attributes"
        value = reflect_on_association(relation_identifier).klass.agent_allowed_params

        if reflect_on_association(relation_identifier).is_a? ActiveRecord::Reflection::HasManyReflection
          value << :_destroy
        end

        { key => value }
      end
    end
  end
end
