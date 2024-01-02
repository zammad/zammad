# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class SignupInputType < Gql::Types::BaseInputObject
    include Gql::Types::Input::Concerns::ProvidesObjectAttributeValues

    description 'The user sign-up fields.'

    argument :login, String, required: false, description: 'The user login'
    argument :firstname, String, required: false, description: 'The user first name'
    argument :lastname, String, required: false, description: 'The user last name'
    argument :email, String, required: true, description: 'The user email'
    argument :password, String, required: true, description: 'The user password'
  end
end
