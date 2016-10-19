# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class OnlineNotification < ApplicationModel
  belongs_to :type_lookup,     class_name: 'TypeLookup'
  belongs_to :object_lookup,   class_name: 'ObjectLookup'
  belongs_to :user

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

  def self.add(data)

    # lookups
    if data[:type]
      type_id = TypeLookup.by_name(data[:type])
    end
    if data[:object]
      object_id = ObjectLookup.by_name(data[:object])
    end

    record = {
      o_id: data[:o_id],
      object_lookup_id: object_id,
      type_lookup_id: type_id,
      seen: data[:seen],
      user_id: data[:user_id],
      created_by_id: data[:created_by_id],
      updated_by_id: data[:updated_by_id] || data[:created_by_id],
      created_at: data[:created_at] || Time.zone.now,
      updated_at: data[:updated_at] || Time.zone.now,
    }

    OnlineNotification.create(record)
  end

=begin

mark online notification as seen

  OnlineNotification.seen(
    id: 2,
  )

=end

  def self.seen(data)
    notification = OnlineNotification.find(data[:id])
    notification.seen = true
    notification.save
  end

=begin

remove whole online notifications of an object

  OnlineNotification.remove('Ticket', 123)

=end

  def self.remove(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)
    OnlineNotification.where(
      object_lookup_id: object_id,
      o_id: o_id,
    ).destroy_all
  end

=begin

remove whole online notifications of an object by type

  OnlineNotification.remove_by_type('Ticket', 123, type, user)

=end

  def self.remove_by_type(object_name, o_id, type, user)
    object_id = ObjectLookup.by_name(object_name)
    type_id = TypeLookup.by_name(type)
    OnlineNotification.where(
      object_lookup_id: object_id,
      type_lookup_id: type_id,
      o_id: o_id,
      user_id: user.id,
    ).destroy_all
  end

=begin

return all online notifications of an user

  notifications = OnlineNotification.list(user, limit)

=end

  def self.list(user, limit)

    notifications = OnlineNotification.where(user_id: user.id)
                                      .order('created_at DESC, id DESC')
                                      .limit(limit)
    list = []
    notifications.each do |item|
      data           = item.attributes
      data['object'] = ObjectLookup.by_id(data['object_lookup_id'])
      data['type']   = TypeLookup.by_id(data['type_lookup_id'])
      data.delete('object_lookup_id')
      data.delete('type_lookup_id')
      list.push data
    end
    list
  end

=begin

return all online notifications of an object

  notifications = OnlineNotification.list_by_object('Ticket', 123)

=end

  def self.list_by_object(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)
    notifications = OnlineNotification.where(
      object_lookup_id: object_id,
      o_id: o_id,
    )
                                      .order('created_at DESC, id DESC')
                                      .limit(10_000)
    notifications
  end

=begin

mark online notification as seen by object

  OnlineNotification.seen_by_object('Ticket', 123, user_id)

=end

  def self.seen_by_object(object_name, o_id)
    object_id     = ObjectLookup.by_name(object_name)
    notifications = OnlineNotification.where(
      object_lookup_id: object_id,
      o_id: o_id,
      seen: false,
    )
    notifications.each do |notification|
      notification.seen = true
      notification.save
    end
    true
  end

=begin

return all online notifications of an user with assets

  OnlineNotification.list_full(user)

returns:

  list = {
    stream: notifications,
    assets: assets,
  }

=end

  def self.list_full(user, limit)

    notifications = OnlineNotification.list(user, limit)
    assets = ApplicationModel.assets_of_object_list(notifications)
    {
      stream: notifications,
      assets: assets
    }
  end

  def notify_clients_after_change
    Sessions.send_to(
      user_id,
      {
        event: 'OnlineNotification::changed',
        data: {}
      }
    )
  end

=begin

check if all notifications are seed for dedecated object

  OnlineNotification.all_seen?('Ticket', 123)

returns:

  true # false

=end

  def self.all_seen?(object, o_id)
    notifications = OnlineNotification.list_by_object(object, o_id)
    notifications.each { |onine_notification|
      return false if !onine_notification['seen']
    }
    true
  end

=begin

check if notification was created for certain user

  OnlineNotification.exists?(for_user, object, o_id, type, created_by_user, seen)

returns:

  true # false

=end

  # rubocop:disable Metrics/ParameterLists
  def self.exists?(user, object, o_id, type, created_by_user, seen)
    # rubocop:enable Metrics/ParameterLists
    notifications = OnlineNotification.list(user, 10)
    notifications.each { |notification|
      next if notification['o_id'] != o_id
      next if notification['object'] != object
      next if notification['type'] != type
      next if notification['created_by_id'] != created_by_user.id
      next if notification['seen'] != seen
      return true
    }
    false
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

  def self.cleanup(max_age = Time.zone.now - 9.months, max_own_seen = Time.zone.now - 10.minutes, max_auto_seen = Time.zone.now - 8.hours)
    OnlineNotification.where('created_at < ?', max_age).delete_all
    OnlineNotification.where('seen = ? AND updated_at < ?', true, max_own_seen).each { |notification|

      # delete own "seen" notificatons after 1 hour
      next if notification.user_id == notification.updated_by_id && notification.updated_at > max_own_seen

      # delete notificatons which are set to "seen" by somebody else after 8 hour
      next if notification.user_id != notification.updated_by_id && notification.updated_at > max_auto_seen

      notification.delete
    }

    # notify all agents
    User.with_permissions('ticket.agent').each { |user|
      Sessions.send_to(
        user.id,
        {
          event: 'OnlineNotification::changed',
          data: {}
        }
      )
      sleep 2 # slow down client requests
    }

    true
  end

end
