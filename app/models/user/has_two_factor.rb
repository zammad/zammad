# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on user changes.
module User::HasTwoFactor
  extend ActiveSupport::Concern

  included do
    has_many :two_factor_preferences, dependent: :destroy do
      def recovery_codes
        recovery_codes_methods.first
      end
    end
  end

  def auth_two_factor
    @auth_two_factor ||= Auth::TwoFactor.new(self)
  end

  def two_factor_setup_required?
    auth_two_factor.user_setup_required?
  end

  def two_factor_configured?
    auth_two_factor.user_configured?
  end

  def two_factor_default
    preferences.dig(:two_factor_authentication, :default)
  end

  def two_factor_enabled_authentication_methods
    auth_two_factor
      .enabled_authentication_methods
      .map do |method|
        {
          method:     method.method_name,
          configured: two_factor_authentication_method_configured?(method),
          default:    two_factor_authentication_method_default?(method),
          # configuration_possible: method.configuration_possible?, # Maybe needed for the e-mail/sms method (like a health check), for later.
        }
      end
  end

  def two_factor_destroy_all_authentication_methods
    auth_two_factor.all_authentication_methods.each do |method|
      auth_two_factor.authentication_method_object(method.method_name)&.destroy_user_config
    end
  end

  def two_factor_verify_configuration?(authentication_method, payload, configuration)
    auth_two_factor.verify_configuration?(authentication_method, payload, configuration)
  end

  private

  def two_factor_authentication_method_configured?(method)
    auth_two_factor.user_authentication_methods.include?(method)
  end

  def two_factor_authentication_method_default?(method)
    auth_two_factor.user_authentication_methods.include?(method) &&
      auth_two_factor.user_default_authentication_method == method
  end
end
