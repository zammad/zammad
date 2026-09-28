# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::HasDownload
  extend ActiveSupport::Concern

  def send_data(...)
    super
    set_null_csp
  end

  def send_file(...)
    super
    set_null_csp
  end

  private

  def send_download_file(view_type)
    store_file = download_file.store_file
    bytesize   = store_file_bytesize!(store_file)
    options    = { filename: download_file.filename, type: download_file.content_type, disposition: download_file.disposition }

    resized_content = download_file.resized_content(view_type)
    return send_data(resized_content, **options) if resized_content

    send_store_file(store_file, bytesize:, **options)
  end

  def send_store_file(store_file, filename:, type:, disposition:, bytesize: store_file_bytesize!(store_file))
    send_file_headers!(filename:, type:, disposition:)
    headers['Content-Length'] = bytesize.to_s
    self.response_body = ::ApplicationController::HasDownload::StoreFileBody.new(store_file)
    set_null_csp
  end

  def store_file_bytesize!(store_file)
    bytesize = store_file.stream_bytesize
    return bytesize if bytesize

    Rails.logger.error "Content of Store::File #{store_file.id} (#{store_file.provider}) is missing."
    raise ActiveRecord::RecordNotFound
  end

  def file_id
    @file_id ||= params[:id]
  end

  def download_file
    @download_file ||= ::ApplicationController::HasDownload::DownloadFile.new(file_id, disposition: sanitized_disposition)
  end

  def sanitized_disposition
    disposition = params.fetch(:disposition, 'inline')
    valid_disposition = %w[inline attachment]
    return disposition if valid_disposition.include?(disposition)

    raise Exceptions::Forbidden, "Invalid disposition #{disposition} requested. Only #{valid_disposition.join(', ')} are valid."
  end

  def set_null_csp
    request.content_security_policy = ActionDispatch::ContentSecurityPolicy.new.tap { |p| p.default_src :none }
  end
end
