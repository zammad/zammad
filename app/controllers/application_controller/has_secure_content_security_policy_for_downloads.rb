# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationController::HasSecureContentSecurityPolicyForDownloads
  extend ActiveSupport::Concern

  included do

    around_action do |_controller, block|

      subscriber = proc do
        policy = ActionDispatch::ContentSecurityPolicy.new
        policy.default_src :none
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
end
