# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  module TagsInterface
    include Gql::Types::BaseInterface

    description 'Assigned tags'

    field :tags, [String, { null: false }], null: false

    def tags
      @object.tag_list
    end
  end
end
