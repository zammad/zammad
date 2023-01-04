# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class BaseEnum < GraphQL::Schema::Enum
    include Gql::Concerns::HasNestedGraphqlName

    # Create an enum type from a list of classes.
    def self.build_class_list_enum(classes)
      classes.each do |klass|
        value graphql_compatible_name(klass.name), value: klass
      end
    end

    # Create an enum type from a list of strings.
    def self.build_string_list_enum(strings)
      strings.each do |string|
        value graphql_compatible_name(string), value: string
      end
    end

    def self.graphql_compatible_name(name)
      name.gsub('::', '__')
    end
  end
end
