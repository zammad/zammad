# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Ticket::Overviews

=begin

all overviews by user

  result = Ticket::Overviews.all(
    current_user: User.find(123),
  )

returns

  result = [overview1, overview2]

=end

  def self.all(data)

    # get customer overviews
    if data[:current_user].role?('Customer')
      role_id = Role.lookup(name: 'Customer').id
      overviews = if data[:current_user].organization_id && data[:current_user].organization.shared
                    Overview.where(role_id: role_id, active: true).order(:prio)
                  else
                    Overview.where(role_id: role_id, organization_shared: false, active: true).order(:prio)
                  end
      overviews_list = []
      overviews.each { |overview|
        user_ids = overview.user_ids
        next if !user_ids.empty? && !user_ids.include?(data[:current_user].id)
        overviews_list.push overview
      }
      return overviews_list
    end

    # get agent overviews
    return if !data[:current_user].role?('Agent')
    role_id = Role.lookup(name: 'Agent').id
    overviews = Overview.where(role_id: role_id, active: true).order(:prio)
    overviews_list = []
    overviews.each { |overview|
      user_ids = overview.user_ids
      next if !user_ids.empty? && !user_ids.include?(data[:current_user].id)
      overviews_list.push overview
    }
    overviews_list
  end

=begin

  result = Ticket::Overviews.index(User.find(123))

returns

 [
  {
    overview: {
      id: 123,
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

  def self.index(user)
    overviews = Ticket::Overviews.all(
      current_user: user,
    )

    # get only tickets with permissions
    access_condition = Ticket.access_condition(user)

    list = []
    overviews.each { |overview|
      query_condition, bind_condition = Ticket.selector2sql(overview.condition, user)

      order_by = "#{overview.order[:by]} #{overview.order[:direction]}"
      if overview.group_by && !overview.group_by.empty?
        order_by = "#{overview.group_by}_id, #{order_by}"
      end

      ticket_result = Ticket.select('id, updated_at')
                            .where(access_condition)
                            .where(query_condition, *bind_condition)
                            .order(order_by)
                            .limit(500)
                            .pluck(:id, :updated_at)

      tickets = []
      ticket_result.each { |ticket|
        ticket_item = {
          id: ticket[0],
          updated_at: ticket[1],
        }
        tickets.push ticket_item
      }
      count = Ticket.where(access_condition).where(query_condition, *bind_condition).count()
      item = {
        overview: {
          id: overview.id,
          view: overview.link,
          updated_at: overview.updated_at,
        },
        tickets: tickets,
        count: count,
      }

      list.push item
    }
    list
  end

end
