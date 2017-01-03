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
    current_user = data[:current_user]

    # get customer overviews
    if current_user.permissions?('ticket.customer')
      overviews = if current_user.organization_id && current_user.organization.shared
                    Overview.where(role_id: current_user.role_ids, active: true).order(:prio)
                  else
                    Overview.where(role_id: current_user.role_ids, organization_shared: false, active: true).order(:prio)
                  end
      overviews_list = []
      overviews.each { |overview|
        user_ids = overview.user_ids
        next if !user_ids.empty? && !user_ids.include?(current_user.id)
        overviews_list.push overview
      }
      return overviews_list
    end

    # get agent overviews
    return [] if !current_user.permissions?('ticket.agent')
    overviews = Overview.where(role_id: current_user.role_ids, active: true).order(:prio)
    overviews_list = []
    overviews.each { |overview|
      user_ids = overview.user_ids
      next if !user_ids.empty? && !user_ids.include?(current_user.id)
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
    return [] if overviews.blank?

    # get only tickets with permissions
    access_condition = Ticket.access_condition(user)

    ticket_attributes = Ticket.new.attributes
    list = []
    overviews.each { |overview|
      query_condition, bind_condition, tables = Ticket.selector2sql(overview.condition, user)

      # validate direction
      raise "Invalid order direction '#{overview.order[:direction]}'" if overview.order[:direction] && overview.order[:direction] !~ /^(ASC|DESC)$/i

      # check if order by exists
      order_by = overview.order[:by]
      if !ticket_attributes.key?(order_by)
        order_by = if ticket_attributes.key?("#{order_by}_id")
                     "#{order_by}_id"
                   else
                     'created_at'
                   end
      end
      order_by = "tickets.#{order_by} #{overview.order[:direction]}"

      # check if group by exists
      if overview.group_by && !overview.group_by.empty?
        group_by = overview.group_by
        if !ticket_attributes.key?(group_by)
          group_by = if ticket_attributes.key?("#{group_by}_id")
                       "#{group_by}_id"
                     end
        end
        if group_by
          order_by = "tickets.#{group_by}, #{order_by}"
        end
      end

      ticket_result = Ticket.select('id, updated_at')
                            .where(access_condition)
                            .where(query_condition, *bind_condition)
                            .joins(tables)
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
      count = Ticket.where(access_condition).where(query_condition, *bind_condition).joins(tables).count()
      item = {
        overview: {
          name: overview.name,
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
