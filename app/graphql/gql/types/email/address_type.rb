# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Email::AddressType < Gql::Types::BaseObject
    description 'Represents a parsed email address.'

    field :email_address, String, description: 'Email address.', method: :address
    field :name, String, description: 'Display name + comment part of email (if any).'
  end
end
