# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class RecentView < ApplicationModel
  belongs_to :object_lookup, class_name: 'ObjectLookup'
  belongs_to :ticket, class_name: 'Ticket', foreign_key: 'o_id'

  after_create  :notify_clients
  after_update  :notify_clients
  after_destroy :notify_clients

  def self.log(object, o_id, user)

    # access check
    return if !access(object, o_id, user)

    # lookups
    object_lookup_id = ObjectLookup.by_name(object)

    # create entry
    record = {
      o_id: o_id,
      recent_view_object_id: object_lookup_id.to_i,
      created_by_id: user.id,
    }
    RecentView.create(record)
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

  def self.list(user, limit = 10, type = nil)
    recent_views = if !type
                     RecentView.select('o_id, recent_view_object_id, MAX(created_at) as created_at, MAX(id) as id')
                               .group(:o_id, :recent_view_object_id)
                               .where(created_by_id: user.id)
                               .limit(limit)
                   elsif type == 'Ticket'
                     state_ids = Ticket::State.by_category(:viewable_agent_new).pluck(:id)
                     RecentView.joins(:ticket)
                               .select('recent_views.o_id as o_id, recent_views.recent_view_object_id as recent_view_object_id, MAX(recent_views.created_at) as created_at, MAX(recent_views.id) as id')
                               .group(:o_id, :recent_view_object_id)
                               .where('recent_views.created_by_id = ? AND recent_views.recent_view_object_id = ? AND tickets.state_id IN (?)', user.id, ObjectLookup.by_name('Ticket'), state_ids )
                               .limit(limit)
                   else
                     RecentView.select('o_id, recent_view_object_id, MAX(created_at) as created_at, MAX(id) as id')
                               .group(:o_id, :recent_view_object_id)
                               .where(created_by_id: user.id, recent_view_object_id: ObjectLookup.by_name(type))
                               .limit(limit)
                   end

    list = []
    recent_views.each { |item|
      data           = item.attributes
      data['object'] = ObjectLookup.by_id(data['recent_view_object_id'])
      data.delete('recent_view_object_id')

      # access check
      next if !access(data['object'], data['o_id'], user)

      # add to result list
      list.push data
    }
    list
  end

  def self.list_full(user, limit = 10)
    recent_viewed = list(user, limit)

    # get related object
    assets = ApplicationModel.assets_of_object_list(recent_viewed)

    {
      stream: recent_viewed,
      assets: assets,
    }
  end

  def notify_clients
    Sessions.send_to(
      created_by_id,
      {
        event: 'RecentView::changed',
        data: {}
      }
    )
  end

  def self.access(object, o_id, user)

    # check if object exists
    begin
      return if !Kernel.const_get(object)
      record = Kernel.const_get(object).lookup(id: o_id)
      return if !record
    rescue
      return
    end

    # check permission
    return if !record.respond_to?(:access?)
    record.access?(user, 'read')
  end

=begin

cleanup old entries

  RecentView.cleanup

optional you can put the max oldest entries as argument

  RecentView.cleanup(1.month)

=end

  def self.cleanup(diff = 1.month)
    RecentView.where('created_at < ?', Time.zone.now - diff).delete_all
    true
  end

end
