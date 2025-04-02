# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
