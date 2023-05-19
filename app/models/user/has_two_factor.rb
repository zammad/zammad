# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on user changes.
module User::HasTwoFactor
  extend ActiveSupport::Concern

  included do
    has_many :two_factor_preferences, dependent: :destroy
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

  def two_factor_enabled_methods
    auth_two_factor
      .enabled_methods
      .map do |method|
        {
          method:     method.method_name,
          configured: two_factor_method_configured?(method),
          default:    two_factor_method_default?(method),

          # configuration_possible: method.configuration_possible?, # TODO: For the e-mail/sms method (like a health check), for later.
        }
      end
  end

  def two_factor_destroy_method(method_name)
    auth_two_factor
      .method_object(method_name)
      .destroy_user_config
  end

  def two_factor_destroy_all_methods
    auth_two_factor.user_methods.each do |method|
      auth_two_factor.method_object(method.method_name).destroy_user_config
    end
  end

  def two_factor_verify_configuration?(method, payload, configuration)
    auth_two_factor.verify_configuration?(method, payload, configuration)
  end

  private

  def two_factor_method_configured?(method)
    auth_two_factor.user_methods.include?(method)
  end

  def two_factor_method_default?(method)
    auth_two_factor.user_methods.include?(method) && auth_two_factor.user_default_method == method
  end
end
