# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class AvatarType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Avatar for users'

    field :default, Boolean, null: false
    field :deletable, Boolean, null: false
    field :initial, Boolean, null: false
    field :image_full, String
    field :image_resize, String

    def self.authorize(_object, ctx)
      ctx.current_user
    end

    def image_full
      get_base64_image_data(object.store_full_id)
    end

    def image_resize
      get_base64_image_data(object.store_resize_id)
    end

    private

    def get_base64_image_data(store_id)
      store = ::Store.find(store_id)
      "data:#{store.preferences['Mime-Type']};base64,#{Base64.strict_encode64(store.content)}"
    end
  end
end
