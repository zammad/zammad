# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class AvatarInputType < Gql::Types::BaseInputObject

    description 'The fields for uploading a new avatar.'

    argument :full, String, required: true, description: 'The full image to use for the avatar (Base64 encoded).'
    argument :resize, String, required: true, description: 'The resized/cropped image to use for the avatar (Base64 encoded).'

    def prepare
      super

      {
        full:   get_and_validate_avatar_data(full),
        resize: get_and_validate_avatar_data(resize)
      }
    end

    private

    def get_and_validate_avatar_data(avatar)
      begin
        file = StaticAssets.data_url_attributes(avatar)
      rescue
        return {
          error_message: __('The image is invalid.')
        }
      end

      web_image_content_types = Rails.application.config.active_storage.web_image_content_types
      if web_image_content_types.exclude?(file[:mime_type])
        return {
          error_message: __('The MIME type of the image is invalid.')
        }
      end

      file
    end
  end
end
