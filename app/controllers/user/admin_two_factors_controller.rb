# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class User::AdminTwoFactorsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def remove_authentication_method
    Service::User::TwoFactor::RemoveMethod
      .new(user: params_user, method_name: params[:method])
      .execute

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
