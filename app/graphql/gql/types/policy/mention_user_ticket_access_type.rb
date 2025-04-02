# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Policy::MentionUserTicketAccessType < Policy::TicketType
    description 'Check Pundit policy queries for the mentioned object and user.'

    def user
      @object.user
    end

    def record
      @object.mentionable
    end
  end
end
