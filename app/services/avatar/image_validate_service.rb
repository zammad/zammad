# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Avatar::ImageValidateService < BaseService
  def execute(args)
    validate_image_data(image_data: args[:image_data])
  end

  private

  def validate_image_data(image_data:)
    begin
      data = StaticAssets.data_url_attributes(image_data)
    rescue
      return error(message: __('The image is invalid.'))
    end

    if !allowed_mime_type?(mime_type: data[:mime_type])
      return error(message: __('The MIME type of the image is invalid.'))
    end

    data
  end

  def allowed_mime_type?(mime_type:)
    return false if Rails.application.config.active_storage.web_image_content_types.exclude?(mime_type)

    true
  end
end
