# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ApplicationController::HasDownload::DownloadFile < SimpleDelegator
  attr_reader :requested_disposition

  def initialize(id, disposition: 'inline')
    @requested_disposition = disposition

    super(Store.find(id))
  end

  def disposition
    return 'attachment' if forcibly_download_as_binary? || !allowed_inline?

    requested_disposition
  end

  def content_type
    return ActiveStorage.binary_content_type if forcibly_download_as_binary?

    file_content_type
  end

  def content(view_type)
    return __getobj__.content if view_type.blank? || !preferences[:resizable]

    return content_inline if content_inline? && view_type == 'inline'
    return content_preview if content_preview? && view_type == 'preview'

    __getobj__.content
  end

  private

  def allowed_inline?
    ActiveStorage.content_types_allowed_inline.include?(content_type)
  end

  def forcibly_download_as_binary?
    ActiveStorage.content_types_to_serve_as_binary.include?(file_content_type)
  end

  def file_content_type
    @file_content_type ||= preferences['Content-Type'] || preferences['Mime-Type'] || ActiveStorage.binary_content_type

    # Workaround for https://github.com/rails/rails/issues/51842
    return @file_content_type if @file_content_type.start_with?('multipart/byteranges')

    @file_content_type.split(';').first
  end

  def content_inline?
    preferences[:content_inline] == true
  end

  def content_preview?
    preferences[:content_preview] == true
  end
end
