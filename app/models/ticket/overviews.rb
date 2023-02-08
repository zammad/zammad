# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Ticket::Overviews

=begin

all overviews by user

  result = Ticket::Overviews.all(current_user: User.find(3))

certain overviews by user

  result = Ticket::Overviews.all(current_user: User.find(3), links: ['all_unassigned', 'my_assigned'])

returns

  result = [overview1, overview2]

=end

  def self.all(data)
    Ticket::OverviewsPolicy::Scope.new(data[:current_user], Overview).resolve
      .where({ link: data[:links] }.compact)
      .distinct
      .order(:prio, :name)
  end

=begin

index of all overviews by user

  result = Ticket::Overviews.index(User.find(3))

index of certain overviews by user

  result = Ticket::Overviews.index(User.find(3), ['all_unassigned', 'my_assigned'])

returns

 [
  {
    overview: {
      id: 123,
      name: 'some name',
      view: 'some_view',
      updated_at: ...,
    },
    count: 3,
    tickets: [
      {
        id: 1,
        updated_at: ...,
      },
      {
        id: 2,
        updated_at: ...,
      },
      {
        id: 3,
        updated_at: ...,
      }
    ],
  },
  {
    ...
  }
 ]

=end

  def self.index(user, links = nil)
    overviews = Ticket::Overviews.all(
      current_user: user,
      links:        links,
    )
    return [] if overviews.blank?

    user_scopes = {
      read:     TicketPolicy::ReadScope.new(user).resolve,
      overview: TicketPolicy::OverviewScope.new(user).resolve,
    }

    overviews.map do |overview|
      db_query_params = _db_query_params(overview, user)

      scope = if overview.condition['ticket.mention_user_ids'].present?
                user_scopes[:read]
              else
                user_scopes[:overview]
              end

      ticket_result = scope
        .distinct
        .where(db_query_params.query_condition, *db_query_params.bind_condition)
        .joins(db_query_params.tables)
        .order(Arel.sql("#{db_query_params.order_by} #{db_query_params.direction}"))
        .limit(limit_per_overview)
        .pluck(:id, :updated_at, Arel.sql(db_query_params.order_by))

      tickets = ticket_result.map do |ticket|
        {
          id:         ticket[0],
          updated_at: ticket[1],
        }
      end

      count = scope
        .distinct
        .where(db_query_params.query_condition, *db_query_params.bind_condition)
        .joins(db_query_params.tables)
        .count

      {
        overview: {
          name:       overview.name,
          id:         overview.id,
          view:       overview.link,
          updated_at: overview.updated_at,
        },
        tickets:  tickets,
        count:    count,
      }
    end
  end

  def self.tickets_for_overview(overview, user, order_by: nil, order_direction: nil)
    db_query_params = _db_query_params(overview, user, order_by: order_by, order_direction: order_direction)

    scope = TicketPolicy::OverviewScope
    if overview.condition['ticket.mention_user_ids'].present?
      scope = TicketPolicy::ReadScope
    end
    scope.new(user).resolve
      .distinct
      .where(db_query_params.query_condition, *db_query_params.bind_condition)
      .joins(db_query_params.tables)
      .order(Arel.sql("#{db_query_params.order_by} #{db_query_params.direction}"))
      .limit(limit_per_overview)
  end

  DB_QUERY_PARAMS = Struct.new(:query_condition, :bind_condition, :tables, :order_by, :direction)

  def self._db_query_params(overview, user, order_by: nil, order_direction: nil)
    result = DB_QUERY_PARAMS.new(*Ticket.selector2sql(overview.condition, current_user: user), order_by || overview.order[:by], order_direction || overview.order[:direction])

    # validate direction
    raise "Invalid order direction '#{result.direction}'" if result.direction && result.direction !~ %r{^(ASC|DESC)$}i

    ticket_attributes = Ticket.new.attributes

    # check if order by exists
    if !ticket_attributes.key?(result.order_by)
      result.order_by = if ticket_attributes.key?("#{result.order_by}_id")
                          "#{result.order_by}_id"
                        else
                          'created_at'
                        end
    end
    result.order_by = "#{ActiveRecord::Base.connection.quote_table_name('tickets')}.#{ActiveRecord::Base.connection.quote_column_name(result.order_by)}"

    # check if group by exists
    if overview.group_by.present?
      group_by = overview.group_by
      if !ticket_attributes.key?(group_by)
        group_by = if ticket_attributes.key?("#{group_by}_id")
                     "#{group_by}_id"
                   end
      end
      if group_by
        result.order_by = "#{ActiveRecord::Base.connection.quote_table_name('tickets')}.#{ActiveRecord::Base.connection.quote_column_name(group_by)}, #{result.order_by}"
      end
    end
    result
  end

  def self.limit_per_overview
    Setting.get('ui_ticket_overview_ticket_limit')
  end
end
