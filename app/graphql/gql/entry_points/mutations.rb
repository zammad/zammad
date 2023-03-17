# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::EntryPoints
  class Mutations < Gql::Types::BaseObject

    description 'All available mutations'

    Mixin::RequiredSubPaths.eager_load_recursive Gql::Mutations, "#{__dir__}/../mutations/"
    Gql::Mutations::BaseMutation.descendants.reject { |klass| klass.name.include?('::Base') }.each do |klass|
      klass.register_in_schema(self)
    end
  end
end
