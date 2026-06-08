# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class BaseArgument < GraphQL::Schema::Argument

    # Allow specifying a custom pundit policy for argument loading.
    attr_reader :loads_pundit_method

    def initialize(*, loads_pundit_method: nil, **, &)
      @loads_pundit_method = loads_pundit_method

      super(*, **, &)
    end

    # Custom handling for arguments where a non-default pundit method needs to be used
    #   for value authorization. By default, graphql-ruby performs authorization of the types,
    #   but there is no argument context available at this point to determine the custom pundit method.
    def authorized?(obj, value, ctx)
      if loads_pundit_method && !authorize_loaded_values?(value, ctx)
        return false
      end

      super
    end

    private

    def authorize_loaded_values?(value, ctx)
      Array(value).all? do |item|
        Pundit.policy(ctx.current_user, item).public_send(loads_pundit_method)
      end
    end
  end
end
