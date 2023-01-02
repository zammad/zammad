# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HasNestedGraphqlName
  extend ActiveSupport::Concern

  included do
    def self.inherited(subclass)
      super
      return if !subclass.name

      subclass.graphql_name(subclass.name.sub(%r{Gql::[^:]+::}, '').gsub('::', '').delete_prefix('Input').sub(%r{Type\Z}, ''))
    end

    def self.graphql_field_name
      graphql_name.camelize(:lower).to_sym
    end
  end
end
