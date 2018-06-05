# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class RecentView < ApplicationModel
  include RecentView::Assets

  # rubocop:disable Rails/InverseOf
  belongs_to :ticket, foreign_key: 'o_id'
  belongs_to :object, class_name: 'ObjectLookup', foreign_key: 'recent_view_object_id'
  # rubocop:enable Rails/InverseOf

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

  def self.list(user, limit = 10, object_name = nil)
    recent_views = if !object_name
                     RecentView.select('o_id, recent_view_object_id, MAX(created_at) as created_at, MAX(id) as id, created_by_id')
                               .group(:o_id, :recent_view_object_id, :created_by_id)
                               .where(created_by_id: user.id)
                               .limit(limit)
                   elsif object_name == 'Ticket'
                     state_ids = Ticket::State.by_category(:viewable_agent_new).pluck(:id)
                     local_recent_views = RecentView.select('o_id, recent_view_object_id, MAX(created_at) as created_at, MAX(id) as id, created_by_id')
                                                    .group(:o_id, :recent_view_object_id, :created_by_id)
                                                    .where(created_by_id: user.id, recent_view_object_id: ObjectLookup.by_name(object_name))
                                                    .limit(limit + 10)
                     clear_list = []
                     local_recent_views.each do |item|
                       ticket = Ticket.find_by(id: item.o_id)
                       next if !ticket
                       next if !state_ids.include?(ticket.state_id)
                       clear_list.push item
                       break if clear_list.count == limit
                     end
                     clear_list
                   else
                     RecentView.select('o_id, recent_view_object_id, MAX(created_at) as created_at, MAX(id) as id, created_by_id')
                               .group(:o_id, :recent_view_object_id, :created_by_id)
                               .where(created_by_id: user.id, recent_view_object_id: ObjectLookup.by_name(object_name))
                               .limit(limit)
                   end

    list = []
    recent_views.each do |item|

      # access check
      next if !access(ObjectLookup.by_id(item['recent_view_object_id']), item['o_id'], user)

      # add to result list
      list.push item
    end
    list
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

  RecentView.cleanup(3.month)

=end

  def self.cleanup(diff = 3.months)
    RecentView.where('created_at < ?', Time.zone.now - diff).delete_all
    true
  end

end
