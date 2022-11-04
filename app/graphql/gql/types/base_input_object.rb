# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class BaseInputObject < GraphQL::Schema::InputObject
    include Gql::Concerns::HasNestedGraphqlName

    argument_class Gql::Types::BaseArgument

    # Add the possibility to specify custom value transformation handlers.
    #
    #   transform :my_transformer
    #
    #   def my_transformer(payload)
    #     ... # return modified payload
    #   end
    class << self
      def transformers
        @transformers || []
      end

      def transform(function_name)
        @transformers ||= []
        @transformers.push(function_name)
      end
    end

    def prepare
      self.class.transformers.reduce(super) do |result, t|
        send(t, result)
      end
    end
  end
end
