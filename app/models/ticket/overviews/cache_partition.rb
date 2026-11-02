# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Users who see the same tickets of an overview share its cached data. A partition captures the access of the current
#   user once per request, keys the cache by it and fills the cache only with tickets inside that access, so that access
#   gained between building the key and loading the tickets does not enter an entry shared with other users.
class Ticket::Overviews::CachePartition
  attr_reader :overview, :user, :group_ids, :read_group_ids, :shared_organization_ids

  def initialize(overview, user)
    @overview                = overview
    @user                    = user
    @group_ids               = request_cached_group_ids(Ticket::Overviews.access_for_overview(overview))
    @read_group_ids          = request_cached_group_ids(:read)
    @shared_organization_ids = request_cached('shared_organization_ids') { TicketPolicy::OverviewScope.new(user).shared_organization_ids.sort }
    @customer                = request_cached('customer') { user.permissions?('ticket.customer') }
    @personal                = refers_to_current_user? || own_tickets_beyond_shared_access?
  end

  def personal?
    @personal
  end

  def key
    parts = [
      "overviewLastUpdate:#{overview.updated_at.to_time.to_i}",
      "groupPermissions:#{group_ids}",
      "readGroupPermissions:#{read_group_ids}",
    ]
    parts << "sharedOrganizations:#{shared_organization_ids}" if shared_organization_ids.present?
    parts << "currentUserId:#{user.id}" if personal?
    parts << "customerId:#{user.id}" if own_customer_access?
    parts.join('-')
  end

  def tickets(order_by: nil, order_direction: nil)
    within_access(Ticket::Overviews.tickets_for_overview(overview, user, order_by:, order_direction:), group_ids)
  end

  # Ticket lists show only tickets the user may read, so they are limited to the captured read access as well.
  def readable_tickets(order_by: nil, order_direction: nil)
    within_access(tickets(order_by:, order_direction:), read_group_ids)
  end

  private

  # The user's access does not depend on the overview, so all partitions of a request share one lookup.
  def request_cached_group_ids(access)
    request_cached("group_ids/#{access}") { user.group_ids_access(access).sort }
  end

  def request_cached(name, &)
    Auth::RequestCache.fetch_value("#{self.class}/#{user.id}/#{name}", &)
  end

  def refers_to_current_user?
    # Stringify so that it works both with simple and expert mode conditions.
    overview.condition.to_s.include?('current_user')
  end

  def customer?
    @customer
  end

  # A personal partition of a customer also holds own tickets outside the shared access, so its key names
  #   that access as well and the entry is left behind once the customer permission is gone.
  def own_customer_access?
    personal? && customer?
  end

  # Own tickets of this overview outside the shared access are seen by this user alone.
  def own_tickets_beyond_shared_access?
    return false if !customer?

    # Own tickets are visible to the user whatever their group access, and an existence check needs no order,
    #   so the overview's selector runs without the authorization scope and the sorting lookups of tickets_for_overview.
    own_tickets = Ticket.raw_selectors(overview.condition, access: 'ignore', current_user: user)
    return false if !own_tickets

    own_tickets = own_tickets.where(customer_id: user.id).where.not(group_id: group_ids & read_group_ids)
    if shared_organization_ids.present?
      own_tickets = own_tickets.where('tickets.organization_id IS NULL OR tickets.organization_id NOT IN (?)', shared_organization_ids)
    end

    own_tickets.exists?
  end

  def within_access(tickets, captured_group_ids)
    return tickets if !tickets

    sql  = ['tickets.group_id IN (?)']
    bind = [captured_group_ids]

    if shared_organization_ids.present?
      sql.push('tickets.organization_id IN (?)')
      bind.push(shared_organization_ids)
    end

    if own_customer_access?
      sql.push('tickets.customer_id = ?')
      bind.push(user.id)
    end

    tickets.where(sql.join(' OR '), *bind)
  end
end
