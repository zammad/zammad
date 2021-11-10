# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::EntryPoints
  class Mutations < Gql::Types::BaseObject
    description 'All available mutations.'

    # No auth required for the main mutation entry point, Gql::mutations perform their own auth handling.
    def self.requires_authentication?
      false
    end

    # Load all available Gql::mutations so that they can be iterated.
    Mixin::RequiredSubPaths.eager_load_recursive("#{__dir__}/../mutations")

    ::Gql::Mutations::BaseMutation.descendants.each do |mutation|
      field_name = mutation.name.sub('Gql::Mutations::', '').gsub('::', '').camelize(:lower).to_sym
      field field_name, mutation: mutation
    end
  end
end
