# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Email::AddressType < Gql::Types::BaseObject
    description 'Represents a parsed email address.'

    field :email_address, String, description: 'Email address.'
    field :name, String, description: 'Display name + comment part of email (if any).'

    # system emails are also called local in desktop, e.g. email_reply.coffee
    field :is_system_address, Boolean, description: 'Is email added as system EmailAddress?', null: false

    def is_system_address
      EmailAddress.exists? email: @object[:email_address]
    end
  end
end
