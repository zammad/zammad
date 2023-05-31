# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class User::TwoFactorsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def two_factor_remove_authentication_method
    params_user.two_factor_destroy_authentication_method(params[:method])

    render json: {}, status: :ok
  end

  def two_factor_remove_all_authentication_methods
    params_user.two_factor_destroy_all_authentication_methods

    render json: {}, status: :ok
  end

  def two_factor_enabled_authentication_methods
    render json: params_user.two_factor_enabled_authentication_methods, status: :ok
  end

  def two_factor_personal_configuration
    result = {
      enabled_authentication_methods: current_user.two_factor_enabled_authentication_methods,
      recovery_codes_exist:           current_user.auth_two_factor.user_recovery_codes_exists?,
    }

    render json: result, status: :ok
  end

  def two_factor_verify_configuration
    raise Exceptions::UnprocessableEntity, __('The required parameter "method" is missing.')  if !params[:method]
    raise Exceptions::UnprocessableEntity, __('The required parameter "payload" is missing.') if !params[:payload]

    verified = two_factor_verify_configuration?

    result = {
      verified: verified,
    }

    if verified
      result[:recovery_codes] = current_user.two_factor_recovery_codes_generate
    end

    render json: result, status: :ok
  end

  def two_factor_authentication_method_configuration
    method_name = params[:method]

    raise Exceptions::UnprocessableEntity, __('The required parameter "method" is missing.') if method_name.blank?

    two_factor_method = current_user.auth_two_factor.authentication_method_object(method_name)

    raise Exceptions::UnprocessableEntity, __('The two-factor authentication method is not enabled.') if !two_factor_method&.enabled? || !two_factor_method&.available?

    render json: { configuration: two_factor_method.configuration_options }, status: :ok
  end

  def two_factor_recovery_codes_generate
    render json: current_user.two_factor_recovery_codes_generate(force: true), status: :ok
  end

  private

  def params_user
    User.find(params[:id])
  end

  def two_factor_verify_configuration?
    current_user.two_factor_verify_configuration?(params[:method], params[:payload], params[:configuration].permit!.to_h)
  end
end
