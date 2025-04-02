# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::ExternalReferences::IssueTracker::Base < Service::Base
  attr_reader :type

  def initialize(type:)
    super()

    @type = type
  end

  private

  def integration_setting_name
    "#{type}_integration"
  end

  def integration_config
    @integration_config ||= begin
      config = Setting.get("#{type}_config")
      config.symbolize_keys
    end
  end

  def issue_tracker_object
    @issue_tracker_object ||= begin
      options = {
        endpoint:  integration_config[:endpoint],
        api_token: integration_config[:api_token]
      }

      options[:verify_ssl] = integration_config[:verify_ssl] if integration_config.key?(:verify_ssl)

      "::#{type.camelize}".constantize.new(**options)
    end
  end
end
