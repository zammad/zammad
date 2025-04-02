# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Adds close time (if missing) when tickets are closed.
class Ticket::Stats
  attr_accessor :user_id, :organization_ids, :current_user, :limit

  def initialize(current_user:, assets:, user_id: nil, organization_id: nil, limit: 100)
    @user_id          = user_id
    @organization_ids = Array.wrap(organization_id)
    @current_user     = current_user
    @limit            = limit
    @assets           = assets
  end

  def list_stats_user
    user = User.lookup(id: user_id)
    return if !user

    result     = {}
    conditions = {
      closed_ids: {
        'ticket.state_id'    => {
          operator: 'is',
          value:    Ticket::State.by_category_ids(:closed),
        },
        'ticket.customer_id' => {
          operator: 'is',
          value:    user.id,
        },
      },
      open_ids:   {
        'ticket.state_id'    => {
          operator: 'is',
          value:    Ticket::State.by_category_ids(:open),
        },
        'ticket.customer_id' => {
          operator: 'is',
          value:    user.id,
        },
      },
    }
    conditions.each do |key, local_condition|
      result[key] = search_stats(local_condition)
    end

    # generate stats by user
    condition = {
      'tickets.customer_id' => user.id,
    }
    result[:volume_by_year] = search_stats_year(condition)
    result
  end

  def list_stats_organization
    result = {}
    organization_ids.select do |organization_id|
      Organization.lookup(id: organization_id).present?
    end
    return if organization_ids.blank?

    conditions = {
      closed_ids: {
        'ticket.state_id'        => {
          operator: 'is',
          value:    Ticket::State.by_category_ids(:closed),
        },
        'ticket.organization_id' => {
          operator: 'is',
          value:    organization_ids,
        },
      },
      open_ids:   {
        'ticket.state_id'        => {
          operator: 'is',
          value:    Ticket::State.by_category_ids(:open),
        },
        'ticket.organization_id' => {
          operator: 'is',
          value:    organization_ids,
        },
      },
    }
    conditions.each do |key, local_condition|
      result[key] = search_stats(local_condition)
    end

    # generate stats by org
    condition = {
      'tickets.organization_id' => organization_ids,
    }
    result[:volume_by_year] = search_stats_year(condition)
    result
  end

  def list_stats
    {
      user:         list_stats_user || {},
      organization: list_stats_organization || {},
      assets:       @assets,
    }
  end

  def search_stats(condition)
    tickets = Ticket.search(
      limit:        limit,
      condition:    condition,
      current_user: current_user,
      sort_by:      'created_at',
      order_by:     'desc',
    )
    assets_of_tickets(tickets)
  end

  def search_stats_year(condition)
    volume_by_year = []
    now            = Time.zone.now

    (0..11).each do |month_back|
      date_to_check = now - month_back.month
      date_start = "#{date_to_check.year}-#{date_to_check.month}-01 00:00:00"
      date_end   = "#{date_to_check.year}-#{date_to_check.month}-#{date_to_check.end_of_month.day} 00:00:00"

      # created
      created = TicketPolicy::ReadScope.new(current_user).resolve
                                       .where(created_at: (date_start..date_end))
                                       .where(condition)
                                       .count

      # closed
      closed = TicketPolicy::ReadScope.new(current_user).resolve
                                      .where(close_at: (date_start..date_end))
                                      .where(condition)
                                      .count

      data = {
        month:   date_to_check.month,
        year:    date_to_check.year,
        text:    Date::MONTHNAMES[date_to_check.month],
        created: created,
        closed:  closed,
      }
      volume_by_year.push data
    end
    volume_by_year
  end

  private

  def assets_of_tickets(tickets)
    ticket_ids = []
    tickets.each do |ticket|
      ticket_ids.push ticket.id
      @assets = ticket.assets(@assets)
    end
    ticket_ids
  end
end
