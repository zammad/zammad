# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

  def self.log(object, o_id, user)
    return if !access(object, o_id, user)

    exists_by_object_and_id?(object, o_id)

    RecentView.create!(o_id:                  o_id,
                       recent_view_object_id: ObjectLookup.by_name(object),
                       created_by_id:         user.id)
  end

  def self.log_destroy(requested_object, requested_object_id)
    return if requested_object == 'RecentView'

    RecentView.where(recent_view_object_id: ObjectLookup.by_name(requested_object))
              .where(o_id: requested_object_id)
              .destroy_all
  end

  def self.user_log_destroy(user)
    RecentView.where(created_by_id: user.id).destroy_all
  end

  def self.list(user, limit = 10, object_name = nil)
    recent_views = RecentView.select('o_id, ' \
                                     'recent_view_object_id, ' \
                                     'created_by_id, ' \
                                     'MAX(created_at) as created_at, ' \
                                     'MAX(id) as id')
                             .group(:o_id, :recent_view_object_id, :created_by_id)
                             .where(created_by_id: user.id)
                             .order(Arel.sql('MAX(created_at) DESC, MAX(id) DESC'))
                             .limit(limit)

    if object_name.present?
      recent_views = recent_views.where(recent_view_object_id: ObjectLookup.by_name(object_name))
    end

    # hide merged / removed tickets in Ticket Merge dialog
    if object_name == 'Ticket'
      recent_views = recent_views.limit(limit * 2)

      viewable_ticket_ids = Ticket.where('id IN (?) AND state_id in (?)',
                                         recent_views.map(&:o_id),
                                         Ticket::State.by_category(:viewable_agent_new).pluck(:id)) # rubocop:disable Rails/PluckInWhere
                                  .pluck(:id)

      recent_views = recent_views.select { |rv| viewable_ticket_ids.include?(rv.o_id) }
                                 .first(limit)
    end

    recent_views.select { |rv| access(ObjectLookup.by_id(rv.recent_view_object_id), rv.o_id, user) }
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

  def self.access(object, o_id, user)
    record = object.to_s
              .safe_constantize
              .try(:lookup, { id: o_id })

    Pundit.policy(user, record).try(:show?)
  end

=begin

cleanup old entries

  RecentView.cleanup

optional you can put the max oldest entries as argument

  RecentView.cleanup(3.month)

=end

  def self.cleanup(diff = 3.months)
    RecentView.where('created_at < ?', Time.zone.now - diff).delete_all
    true
  end

end
