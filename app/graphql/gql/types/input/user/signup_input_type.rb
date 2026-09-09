# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class SignupInputType < Gql::Types::BaseInputObject
    description 'The user sign-up fields.'

    argument :firstname, String, required: false, description: 'The user first name'
    argument :lastname, String, required: false, description: 'The user last name'
    argument :email, String, required: true, description: 'The user email'
    argument :password, String, required: true, description: 'The user password'
  end
end
