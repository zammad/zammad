# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class AvatarInputType < Gql::Types::BaseInputObject

    description 'The fields for uploading a new avatar.'

    argument :original, Gql::Types::Input::UploadFileInputType, description: 'The original image to use for the avatar.'
    argument :resized, Gql::Types::Input::UploadFileInputType, description: 'The resized/cropped image to use for the avatar.'

    def prepare
      super

      service = Service::Avatar::ImageValidate.new

      {
        original: service.execute(image_data: original),
        resized:  service.execute(image_data: resized)
      }
    end
  end
end
