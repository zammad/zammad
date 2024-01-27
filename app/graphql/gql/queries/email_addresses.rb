# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class EmailAddresses < BaseQuery

    description 'EmailAddresses available in the system'

    argument :only_active, Boolean, required: false, description: 'Fetch only active addresses'

    type [Gql::Types::EmailAddressType, { null: false }], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent', 'admin.channel_email', 'admin.wizard'])
    end

    def resolve(only_active: false)
      return EmailAddress.where(active: true) if only_active

      EmailAddress.all
    end
  end
end
