# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class BaseEnum < GraphQL::Schema::Enum
    include Gql::Concerns::HasNestedGraphqlName

    # Create an enum type from a list of classes.
    def self.build_class_list_enum(classes)
      classes.each do |klass|
        # Convert to a GraphQL compatible name.
        value klass.name.gsub('::', '__'), value: klass
      end
    end
  end
end
