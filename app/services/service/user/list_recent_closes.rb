# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::ListRecentCloses < Service::Base
  requires_current_user!

  attr_reader :limit

  def initialize(limit: 10)
    @limit = limit
  end

  def execute
    objects_in_order
  end

  private

  def ordered_recent_closes
    @ordered_recent_closes ||= current_user.recent_closes.reorder(updated_at: :desc).limit(limit)
  end

  def grouped_recent_closes
    @grouped_recent_closes ||= ordered_recent_closes.group_by(&:recently_closed_object_type)
  end

  def objects_in_order
    @objects_in_order ||= ordered_recent_closes
      .filter_map do |item|
        case item.recently_closed_object_type
        when 'Ticket'
          tickets.find { it.id == item.recently_closed_object_id }
        when 'Organization'
          organizations.find { it.id == item.recently_closed_object_id }
        when 'User'
          users.find { it.id == item.recently_closed_object_id }
        end
      end
  end

  def tickets
    @tickets ||= fetch_tickets
  end

  def organizations
    @organizations ||= fetch_organizations
  end

  def users
    @users ||= fetch_users
  end

  def fetch_tickets
    return [] if grouped_recent_closes['Ticket'].blank?

    ticket_ids = grouped_recent_closes['Ticket'].map(&:recently_closed_object_id)

    TicketPolicy::ReadScope
      .new(current_user)
      .resolve
      .where(id: ticket_ids)
      .to_a
  end

  def fetch_organizations
    return [] if grouped_recent_closes['Organization'].blank?

    organization_ids = grouped_recent_closes['Organization'].map(&:recently_closed_object_id)

    OrganizationPolicy::Scope
      .new(current_user, Organization.all)
      .resolve
      .where(id: organization_ids)
      .to_a
  end

  def fetch_users
    return [] if grouped_recent_closes['User'].blank?

    user_ids = grouped_recent_closes['User'].map(&:recently_closed_object_id)

    UserPolicy::Scope
      .new(current_user, User.all)
      .resolve
      .where(id: user_ids)
      .to_a
  end
end
