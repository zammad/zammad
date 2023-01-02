# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::HasDownload
  extend ActiveSupport::Concern

  included do
    around_action do |_controller, block|

      subscriber = proc do
        policy = ActionDispatch::ContentSecurityPolicy.new
        policy.default_src :none

        # The 'plugin_types' rule is deprecated and should be changed in the future.
        policy.plugin_types 'application/pdf'

        request.content_security_policy = policy
      end

      ActiveSupport::Notifications.subscribed(subscriber, 'send_file.action_controller') do
        ActiveSupport::Notifications.subscribed(subscriber, 'send_data.action_controller') do
          block.call
        end
      end
    end
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
end
