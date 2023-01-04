# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Fields
  # Represents internal fields like 'note' which can only be accessed with admin/agent permission.
  class InternalField < BaseField
    def resolve(object, args, context)
      authorize_field(context) ? super(object, args, context) : nil
    end

    private

    def authorize_field(context)
      context.current_user.permissions? ['ticket.agent', 'admin.*']
    end
  end
end
