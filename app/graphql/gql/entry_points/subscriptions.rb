# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::EntryPoints
  class Subscriptions < Gql::Types::BaseObject
    # Don't implement the nodes query interface for security reasons.
    #   IDs can be generated on the client side and used to fetch all records from the database.

    description 'All available subscriptions'

    Mixin::RequiredSubPaths.eager_load_recursive Gql::Subscriptions, "#{__dir__}/../subscriptions/"
    Gql::Subscriptions::BaseSubscription.descendants.reject { |klass| klass.name.include?('::Base') }.each do |klass|
      klass.register_in_schema(self)
    end
  end
end
