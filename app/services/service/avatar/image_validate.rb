# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Avatar::ImageValidate < Service::Base
  def execute(image_data:)
    begin
      raise if image_data.nil?

      data = image_data.is_a?(String) ? ImageHelper.data_url_attributes(image_data) : image_data
    rescue
      return error(message: __('The image is invalid.'))
    end

    if !allowed_mime_type?(mime_type: data[:type] || data[:mime_type])
      return error(message: __('The MIME type of the image is invalid.'))
    end

    data
  end

  def allowed_mime_type?(mime_type:)
    !Rails.application.config.active_storage.web_image_content_types.exclude?(mime_type)
  end

  def error(message:)
    {
      message: message,
      error:   true
    }
  end
end
