# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class User::TwoFactorsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  before_action :validate_token!, except: %i[personal_configuration default_authentication_method]

  def remove_authentication_method
    Service::User::TwoFactor::RemoveMethod
      .with_current_user(current_user)
      .execute(method_name: params[:method])

    render json: {}

    token_object.destroy
  end

  def enabled_authentication_methods
    render json: current_user.two_factor_enabled_authentication_methods
  end

  def personal_configuration
    result = {
      enabled_authentication_methods: current_user.two_factor_enabled_authentication_methods,
      recovery_codes_exist:           current_user.auth_two_factor.user_recovery_codes_exists?,
    }

    render json: result
  end

  def verify_configuration
    verify_method_configuration = Service::User::TwoFactor::VerifyMethodConfiguration
      .with_current_user(current_user)
      .execute(method_name: params_method_name, payload: params_payload, configuration: params[:configuration].permit!.to_h)

    render json: verify_method_configuration.merge({ verified: true })

    token_object.destroy
  rescue Service::User::TwoFactor::VerifyMethodConfiguration::Failed
    render json: { verified: false }
  end

  def authentication_method_initiate_configuration
    initiate_authentication_method_configuration = Service::User::TwoFactor::InitiateMethodConfiguration
      .with_current_user(current_user)
      .execute(method_name: params_method_name)

    render json: { configuration: initiate_authentication_method_configuration }
  end

  def recovery_codes_generate
    codes = Service::User::TwoFactor::GenerateRecoveryCodes
      .with_current_user(current_user)
      .execute(force: true)

    render json: codes

    token_object.destroy
  end

  def default_authentication_method
    Service::User::TwoFactor::SetDefaultMethod
      .with_current_user(current_user)
      .execute(method_name: params_method_name)

    render json: {}
  end

  def authentication_method_configuration
    configuration = Service::User::TwoFactor::GetMethodConfiguration
      .with_current_user(current_user)
      .execute(method_name: params_method_name)

    render json: { configuration: configuration || {} }
  end

  def authentication_remove_credentials
    Service::User::TwoFactor::RemoveMethodCredentials
      .with_current_user(current_user)
      .execute(method_name: params_method_name, credential_id: params[:credential_id])

    render json: {}
  end

  private

  def params_method_name
    params.require(:method)
  end

  def params_payload
    params.require(:payload)
  end

  def token_object
    @token_object ||= Token.validate! action: 'PasswordCheck', token: params[:token]
  end

  def validate_token!
    token_object
  rescue Token::TokenInvalid
    render json: { invalid_password_token: true }
  end
end
