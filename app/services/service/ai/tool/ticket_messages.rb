# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The messages of a ticket as the tools read and number them: those GraphQL lists for the user, without system
#   notifications, in order. Every tool that names a message by its position counts the same messages.
class Service::AI::Tool::TicketMessages
  # @return [ActiveRecord::Relation<Ticket::Article>]
  def self.of(ticket, user:)
    Service::Ticket::Article::List
      .with_current_user(user)
      .execute(ticket:)
      .without_system_notifications
  end

  # @param messages [ActiveRecord::Relation<Ticket::Article>] as .of gives them
  # @return [Hash{Integer => Integer}] each message's position by its ID
  def self.positions(messages)
    messages.pluck(:id).each_with_index.to_h { |id, index| [id, index + 1] }
  end
end
