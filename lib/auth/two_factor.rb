# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth::TwoFactor

  attr_reader :user, :all_methods

  def self.method_classes
    @method_classes ||= Auth::TwoFactor::Method.descendants
  end

  def initialize(user)
    @user = user

    @all_methods = self.class.method_classes.map { |method| method.new(user) }
  end

  def enabled?
    enabled_methods.present?
  end

  def available_methods
    all_methods.select(&:available?)
  end

  def enabled_methods
    available_methods.select(&:enabled?)
  end

  def verify?(method, payload)
    return false if method.nil?

    method_object = method_object(method)
    return false if method_object.nil?

    result = method_object.verify(payload)

    return false if !result[:verified]

    method_object.update_user_config(result.except(:verified))

    true
  end

  def verify_configuration?(method, payload, configuration)
    return false if method.nil?

    method_object = method_object(method)
    return false if method_object.nil?

    result = method_object.verify(payload, configuration)

    return false if !result[:verified]

    method_object.create_user_config(result.except(:verified))

    true
  end

  def method_object(method)
    all_methods.find { |all_method| all_method.method_name.eql?(method) }
  end

  def user_methods
    enabled_methods.select { |method| user_two_factor_configuration.key?(method.method_name.to_sym) }
  end

  def user_default_method
    # TODO: For now, the first method defines the default method for a user.
    #   In the long run, this should be selectable by the user.

    enabled_methods.first
  end

  def user_setup_required?
    enabled? && !user_configured? && Setting.get('two_factor_authentication_enforce_role_ids').any? { |role_id| user.role_ids.include? role_id.to_i }
  end

  def user_configured?
    user_methods.present?
  end

  private

  def user_two_factor_configuration
    return if user.two_factor_preferences.nil?

    user.two_factor_preferences.to_h do |two_factor_pref|
      [
        two_factor_pref.method.to_sym,
        two_factor_pref.configuration,
      ]
    end
  end
end
