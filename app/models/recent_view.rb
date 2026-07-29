# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RecentView < ApplicationModel
  include RecentView::Assets

  # rubocop:disable Rails/InverseOf
  belongs_to :ticket, foreign_key: 'o_id', optional: true
  belongs_to :object, class_name: 'ObjectLookup', foreign_key: 'recent_view_object_id', optional: true
  belongs_to :created_by, class_name: 'User'
  # rubocop:enable Rails/InverseOf

  after_create  :notify_clients
  after_update  :notify_clients
  after_destroy :notify_clients

  association_attributes_ignored :created_by

  scope :for_object, ->(object) { where(recent_view_object_id: ObjectLookup.by_name(object.class.name), o_id: object.id) }

  def self.log(object, user)
    transaction do
      for_object(object)
        .create_or_find_by(created_by_id: user.id)
        .tap { it.update!(updated_at: Time.current) if !it.previously_new_record? }
    end
  end

  def self.log_destroy(object)
    for_object(object).destroy_all
  end

  def self.user_log_destroy(user)
    where(created_by: user).destroy_all
  end

  def self.list(user, limit = 10, object_name = nil)
    recent_views = where(created_by_id: user.id)
                   .reorder(updated_at: :desc, id: :desc)
                   .limit(limit)

    if object_name.present?
      recent_views = recent_views.where(recent_view_object_id: ObjectLookup.by_name(object_name))
    end

    # hide merged / removed tickets in Ticket Merge dialog
    if object_name == 'Ticket'
      # fetch extra entries to compensate for the merged / removed and unauthorized
      # tickets that get filtered out below, so we can still fill up to `limit`
      recent_views = recent_views.limit(limit * 2)

      viewable_ticket_ids = Ticket.where(id: recent_views.map(&:o_id), state_id: Ticket::State.by_category_ids(:viewable_agent_new))
                                  .pluck(:id)

      recent_views = recent_views.select { |rv| viewable_ticket_ids.include?(rv.o_id) }
    end

    authorized(recent_views, user).first(limit)
  end

  # Authorize recent views per object type, using one query per type where a
  # policy scope is available, while preserving the original order.
  def self.authorized(recent_views, user)
    recent_views = recent_views.to_a

    authorized_ids = recent_views
                     .group_by { |recent_view| ObjectLookup.by_id(recent_view.recent_view_object_id) }
                     .to_h { |object_name, views| [object_name, authorized_object_ids(object_name, views.map(&:o_id), user)] }

    recent_views.select do |recent_view|
      authorized_ids[ObjectLookup.by_id(recent_view.recent_view_object_id)].include?(recent_view.o_id)
    end
  end

  def self.authorized_object_ids(object_name, o_ids, user)
    case object_name
    when 'Ticket'
      TicketPolicy::ReadScope.new(user).resolve.where(id: o_ids).pluck(:id).to_set
    when 'Organization'
      OrganizationPolicy::Scope.new(user, Organization).resolve.where(id: o_ids).pluck(:id).to_set
    when 'User'
      # UserPolicy::Scope is narrower than UserPolicy#show?: it implements neither the
      #   'admin.*' nor the same organization branch. Authorize per record instead, so
      #   users that may actually be seen are not dropped from the list.
      User.where(id: o_ids).select { UserPolicy.new(user, it).show? }.to_set(&:id)
    else
      Set.new
    end
  end

  def notify_clients
    Sessions.send_to(
      created_by_id,
      {
        event: 'RecentView::changed',
        data:  {}
      }
    )
  end

=begin

cleanup old entries

  RecentView.cleanup

optional you can put the max oldest entries as argument

  RecentView.cleanup(3.month)

=end

  def self.cleanup(diff = 3.months)
    where(updated_at: ...diff.ago)
      .delete_all

    true
  end

end
