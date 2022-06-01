# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class LoginInputType < Gql::Types::BaseInputObject

    description 'The user login fields.'

    argument :login, String, required: true, description: 'User name'
    argument :password, String, required: true, description: 'Password'
    argument :fingerprint, String, required: true, description: 'Device fingerprint - a string identifying the device used for the login'
    argument :remember_me, Boolean, required: false, description: 'Remember me - Session expire date will be set to one year'
  end
end
