# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class User::AdminTwoFactorsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # calls the model method directly instead of Service::User::TwoFactor::RemoveMethod,
  # because the service would execute as the target user and break audit log attribution
  def remove_authentication_method
    params_user.two_factor_destroy_authentication_method(params[:method])

    render json: {}
  end

  def remove_all_authentication_methods
    params_user.two_factor_destroy_all_authentication_methods

    render json: {}
  end

  def enabled_authentication_methods
    render json: params_user.two_factor_enabled_authentication_methods
  end

  private

  def params_user
    User.find(params[:id])
  end
end
