# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ActivityStreamPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      permission_scope.merge(readable_object_scope)
    end

    private

    def permission_scope
      if customer?
        scope.where(id: nil)
      elsif group_ids.blank?
        scope.where(permission_id: permission_ids, group_id: nil)
      else
        scope.where(permission_id: [*permission_ids, nil], group_id: [*group_ids, nil])
          .where.not('activity_streams.permission_id IS NULL AND activity_streams.group_id IS NULL')
      end
    end

    # `group_id` is a snapshot of the moment the entry was written, so entries about tickets are
    #   authorized against the current state of the ticket instead. Entries about other objects
    #   are authorized by `permission_id` in `permission_scope`.
    def readable_object_scope
      joined_scope = scope.joins(ticket_join)

      joined_scope.where.not(activity_stream_object_id: [ticket_object_id, article_object_id])
        .or(joined_scope.merge(TicketPolicy::ReadScope.new(user).resolve))
    end

    # Joins the ticket of an entry, directly or via its article, so that
    #   `TicketPolicy::ReadScope` can be applied to it.
    def ticket_join
      ActivityStream.sanitize_sql_array(
        [
          <<~SQL.squish,
            LEFT JOIN ticket_articles
              ON activity_streams.activity_stream_object_id = :article_object_id
              AND ticket_articles.id = activity_streams.o_id
            LEFT JOIN tickets
              ON tickets.id = CASE activity_streams.activity_stream_object_id
                                WHEN :ticket_object_id  THEN activity_streams.o_id
                                WHEN :article_object_id THEN ticket_articles.ticket_id
                              END
          SQL
          { ticket_object_id: ticket_object_id, article_object_id: article_object_id }
        ]
      )
    end

    def ticket_object_id
      @ticket_object_id ||= ObjectLookup.by_name('Ticket')
    end

    def article_object_id
      @article_object_id ||= ObjectLookup.by_name('Ticket::Article')
    end

    def customer?
      !user.permissions?(%w[admin ticket.agent])
    end

    def permission_ids
      @permission_ids ||= user.permissions_with_child_ids
    end

    def group_ids
      @group_ids ||= user.group_ids_access('read')
    end
  end
end
