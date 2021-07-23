# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

    ticket_attributes = Ticket.new.attributes
    overviews.map do |overview|
      query_condition, bind_condition, tables = Ticket.selector2sql(overview.condition, current_user: user)
      direction = overview.order[:direction]
      order_by = overview.order[:by]

      # validate direction
      raise "Invalid order direction '#{direction}'" if direction && direction !~ %r{^(ASC|DESC)$}i

      # check if order by exists
      if !ticket_attributes.key?(order_by)
        order_by = if ticket_attributes.key?("#{order_by}_id")
                     "#{order_by}_id"
                   else
                     'created_at'
                   end
      end
      order_by = "#{ActiveRecord::Base.connection.quote_table_name('tickets')}.#{ActiveRecord::Base.connection.quote_column_name(order_by)}"

      # check if group by exists
      if overview.group_by.present?
        group_by = overview.group_by
        if !ticket_attributes.key?(group_by)
          group_by = if ticket_attributes.key?("#{group_by}_id")
                       "#{group_by}_id"
                     end
        end
        if group_by
          order_by = "#{ActiveRecord::Base.connection.quote_table_name('tickets')}.#{ActiveRecord::Base.connection.quote_column_name(group_by)}, #{order_by}"
        end
      end

      scope = TicketPolicy::OverviewScope
      if overview.condition['ticket.mention_user_ids'].present?
        scope = TicketPolicy::ReadScope
      end
      ticket_result = scope.new(user).resolve
                                                .distinct
                                                .where(query_condition, *bind_condition)
                                                .joins(tables)
                                                .order(Arel.sql("#{order_by} #{direction}"))
                                                .limit(2000)
                                                .pluck(:id, :updated_at, Arel.sql(order_by))

      tickets = ticket_result.map do |ticket|
        {
          id:         ticket[0],
          updated_at: ticket[1],
        }
      end

      count = TicketPolicy::OverviewScope.new(user).resolve
                                                              .distinct
                                                              .where(query_condition, *bind_condition)
                                                              .joins(tables)
                                                              .count()

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

end
