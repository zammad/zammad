# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class AvatarInputType < Gql::Types::BaseInputObject

    description 'The fields for uploading a new avatar.'

    argument :full, String, description: 'The full image to use for the avatar (Base64 encoded).'
    argument :resize, String, description: 'The resized/cropped image to use for the avatar (Base64 encoded).'

    def prepare
      super

      {
        full:   execute_service(Avatar::ImageValidateService, image_data: full),
        resize: execute_service(Avatar::ImageValidateService, image_data: resize)
      }
    end
  end
end
