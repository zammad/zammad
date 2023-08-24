# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class OnlineNotification < ApplicationModel
  include HasDefaultModelUserRelations

  include OnlineNotification::Assets
  include OnlineNotification::TriggersSubscriptions

  belongs_to :user, optional: true
  # rubocop:disable Rails/InverseOf
  belongs_to :object, class_name: 'ObjectLookup', foreign_key: 'object_lookup_id', optional: true
  belongs_to :type,   class_name: 'TypeLookup',   foreign_key: 'type_lookup_id', optional: true
  # rubocop:enable Rails/InverseOf

  after_create    :notify_clients_after_change
  after_update    :notify_clients_after_change
  after_destroy   :notify_clients_after_change

=begin

add a new online notification for this user

  OnlineNotification.add(
    type:          'Assigned to you',
    object:        'Ticket',
    o_id:          ticket.id,
    seen:          false,
    user_id:       2,
    created_by_id: 1,
    updated_by_id: 1,
    created_at:    Time.zone.now,
    updated_at:    Time.zone.now,
  )

=end

  def related_object
    ObjectLookup
      .by_id(object_lookup_id)
      &.safe_constantize
      &.find(o_id)
  end

  def self.add(data)

    # lookups
    if data[:type]
      type_id = TypeLookup.by_name(data[:type])
    end
    if data[:object]
      object_id = ObjectLookup.by_name(data[:object])
    end

    # check if object for online notification exists
    exists_by_object_and_id?(data[:object], data[:o_id])

    record = {
      o_id:             data[:o_id],
      object_lookup_id: object_id,
      type_lookup_id:   type_id,
      seen:             data[:seen],
      user_id:          data[:user_id],
      created_by_id:    data[:created_by_id],
      updated_by_id:    data[:updated_by_id] || data[:created_by_id],
      created_at:       data[:created_at] || Time.zone.now,
      updated_at:       data[:updated_at] || Time.zone.now,
    }

    OnlineNotification.create!(record)
  end

=begin

remove whole online notifications of an object

  OnlineNotification.remove('Ticket', 123)

=end

  def self.remove(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)
    OnlineNotification.where(
      object_lookup_id: object_id,
      o_id:             o_id,
    ).destroy_all
  end

=begin

remove whole online notifications of an object by type

  OnlineNotification.remove_by_type('Ticket', 123, type, user)

=end

  def self.remove_by_type(object_name, o_id, type_name, user)
    object_id = ObjectLookup.by_name(object_name)
    type_id = TypeLookup.by_name(type_name)
    OnlineNotification.where(
      object_lookup_id: object_id,
      type_lookup_id:   type_id,
      o_id:             o_id,
      user_id:          user.id,
    ).destroy_all
  end

=begin

return online notifications of an user.

@param user [User] to get notifications of
@param limit [Integer] of notifications to get
@param ensure_access [Boolean] to check if user still has access to referenced ticket
@param access [String] can be 'full', 'read', 'create' or 'ignore' (ignore means a selector over all tickets)

@example

  notifications = OnlineNotification.list(user, limit: 123, access: 'full')

=end

  def self.list(user, limit: 200, access: 'read')
    relation = OnlineNotification
      .where(user_id: user.id)
      .reorder(created_at: :desc)
      .limit(limit)

    return relation if access == 'ignore'

    object_id = ObjectLookup.by_name 'Ticket'

    relation
      .joins("LEFT JOIN tickets ON online_notifications.object_lookup_id = #{ActiveRecord::Base.connection.quote(object_id)} AND tickets.id = online_notifications.o_id")
      .where('online_notifications.object_lookup_id != :object_id OR (online_notifications.object_lookup_id = :object_id AND tickets.group_id IN (:group_ids))',
             object_id: object_id,
             group_ids: user.group_ids_access(access))
  end

=begin

return all online notifications of an object

  notifications = OnlineNotification.list_by_object('Ticket', 123)

=end

  def self.list_by_object(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)

    OnlineNotification
      .where(
        object_lookup_id: object_id,
        o_id:             o_id,
      )
      .reorder(created_at: :desc)
      .limit(10_000)
  end

=begin

cleanup old online notifications

  OnlineNotification.cleanup

with dedicated times

  max_age = Time.zone.now - 9.months
  max_own_seen = Time.zone.now - 10.minutes
  max_auto_seen = Time.zone.now - 8.hours

  OnlineNotification.cleanup(max_age, max_own_seen, max_auto_seen)

=end

  def self.cleanup(max_age = 9.months.ago, max_own_seen = 10.minutes.ago, max_auto_seen = 8.hours.ago)
    OnlineNotification.where('created_at < ?', max_age).delete_all
    OnlineNotification.where('seen = ? AND updated_at < ?', true, max_own_seen).each do |notification|

      # delete own "seen" notifications after 1 hour
      next if notification.user_id == notification.updated_by_id && notification.updated_at > max_own_seen

      # delete notifications which are set to "seen" by somebody else after 8 hours
      next if notification.user_id != notification.updated_by_id && notification.updated_at > max_auto_seen

      notification.delete
    end

    # notify all agents
    User.with_permissions('ticket.agent').each do |user|
      Sessions.send_to(
        user.id,
        {
          event: 'OnlineNotification::changed',
          data:  {}
        }
      )
      sleep 2 # slow down client requests
    end

    true
  end

  private

  def notify_clients_after_change
    Sessions.send_to(
      user_id,
      {
        event: 'OnlineNotification::changed',
        data:  {}
      }
    )
  end
end
