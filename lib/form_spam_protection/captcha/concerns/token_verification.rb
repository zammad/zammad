# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormSpamProtection::Captcha
  # Shared verification for CAPTCHA providers that render a widget which yields a
  # response token, verified server-side via an HTTP "siteverify" call. Including
  # providers define #provider_config (verify_url, script_url, widget_class,
  # response_field and, optionally, global — the JS object exposing a render
  # function).
  module Concerns::TokenVerification
    extend ActiveSupport::Concern

    def verify(submission)
      response = submission.params[provider_config[:response_field]]
      if response.blank?
        Rails.logger.debug { "Form spam protection: rejected submission (missing #{self.class.key} response)." }
        return false
      end

      if secret.blank?
        Rails.logger.error "Form spam protection: #{self.class.key} is selected but no secret is configured."
        return false
      end

      data = siteverify(response, submission.request)
      return false if data.nil?

      return true if accepted?(data)

      Rails.logger.debug { "Form spam protection: rejected submission (#{self.class.key} verification failed)." }
      false
    end

    private

    # @return [Hash] provider endpoints and widget wiring; defined by each provider.
    def provider_config
      raise NotImplementedError
    end

    # @return [Boolean] whether the provider response counts as a pass; overridden
    #   by score-based providers (e.g. reCAPTCHA v3) to also require a minimum score.
    def accepted?(data)
      data['success'] == true
    end

    def widget_config
      config = provider_config

      {
        type:            config[:type] || 'widget',
        script_url:      config[:script_url],
        widget_class:    config[:widget_class],
        response_field:  config[:response_field],
        global:          config[:global],
        site_key:        site_key,
        action:          config[:action],
        widget_instance: config[:widget_instance],
      }
    end

    # @return [Hash, nil] parsed provider response, or nil on a transport failure.
    def siteverify(response, request)
      result = UserAgent.post(provider_config[:verify_url], siteverify_params(response, request).compact, { verify_ssl: true })

      if !result.success?
        Rails.logger.error "Form spam protection: #{self.class.key} request failed (HTTP #{result.code})."
        return nil
      end

      JSON.parse(result.body.to_s)
    rescue => e
      Rails.logger.error "Form spam protection: #{self.class.key} verification error (#{e.message})."
      nil
    end

    def siteverify_params(response, request)
      {
        secret:   secret,
        response: response,
        remoteip: request&.remote_ip,
      }
    end
  end
end
