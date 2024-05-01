# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class User::TwoFactorsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def two_factor_remove_authentication_method
    Service::User::TwoFactor::RemoveMethod
      .new(user: params_user, method_name: params[:method])
      .execute

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
    raise Exceptions::UnprocessableEntity, __('The required parameter "method" is missing.')  if params[:method].blank?
    raise Exceptions::UnprocessableEntity, __('The required parameter "payload" is missing.') if params[:payload].blank?

    verify_method_configuration = Service::User::TwoFactor::VerifyMethodConfiguration.new(user: current_user, method_name: params[:method], payload: params[:payload], configuration: params[:configuration].permit!.to_h)

    begin
      render json: verify_method_configuration.execute.merge({ verified: true }), status: :ok
    rescue Service::User::TwoFactor::VerifyMethodConfiguration::Failed
      render json: { verified: false }, status: :ok
    end
  end

  def two_factor_authentication_method_initiate_configuration
    check_method!

    initiate_authentication_method_configuration = Service::User::TwoFactor::InitiateMethodConfiguration.new(user: current_user, method_name: @method_name)

    render json: { configuration: initiate_authentication_method_configuration.execute }, status: :ok
  end

  def two_factor_recovery_codes_generate
    codes = Service::User::TwoFactor::GenerateRecoveryCodes
      .new(user: current_user, force: true)
      .execute

    render json: codes, status: :ok
  end

  def two_factor_default_authentication_method
    check_method!

    Service::User::TwoFactor::SetDefaultMethod
      .new(user: current_user, method_name: @method_name)
      .execute

    render json: {}, status: :ok
  end

  def two_factor_authentication_method_configuration
    check_method!

    configuration = Service::User::TwoFactor::GetMethodConfiguration
      .new(user: current_user, method_name: @method_name)
      .execute

    render json: { configuration: configuration || {} }, status: :ok
  end

  def two_factor_authentication_remove_credentials
    check_method!

    Service::User::TwoFactor::RemoveMethodCredentials
      .new(user: current_user, method_name: @method_name, credential_id: params[:credential_id])
      .execute

    render json: {}, status: :ok
  end

  private

  def check_method!
    raise Exceptions::UnprocessableEntity, __('The required parameter "method" is missing.') if params[:method].blank?

    @method_name ||= params[:method]

    true
  end

  def params_user
    User.find(params[:id])
  end
end
