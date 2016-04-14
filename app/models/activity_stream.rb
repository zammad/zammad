# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ActivityStream < ApplicationModel
  self.table_name = 'activity_streams'
  belongs_to :activity_stream_type,     class_name: 'TypeLookup'
  belongs_to :activity_stream_object,   class_name: 'ObjectLookup'

=begin

add a new activity entry for an object

  ActivityStream.add(
    type: 'update',
    object: 'Ticket',
    role: 'Admin',
    o_id: ticket.id,
    created_by_id: 1,
    created_at: '2013-06-04 10:00:00',
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

    role_id = nil
    if data[:role]
      role = Role.lookup(name: data[:role])
      if !role
        raise "No such Role #{data[:role]}"
      end
      role_id = role.id
    end

    # check newest entry - is needed
    result = ActivityStream.where(
      o_id: data[:o_id],
      #:activity_stream_type_id  => type_id,
      role_id: role_id,
      activity_stream_object_id: object_id,
      created_by_id: data[:created_by_id]
    ).order('created_at DESC, id DESC').first

    # resturn if old entry is really fresh
    if result
      activity_record_delay = if ENV['ZAMMAD_ACTIVITY_RECORD_DELAY']
                                ENV['ZAMMAD_ACTIVITY_RECORD_DELAY'].to_i.seconds
                              else
                                90.seconds
                              end
      return result if result.created_at.to_i >= ( data[:created_at].to_i - activity_record_delay )
    end

    # create history
    record = {
      o_id: data[:o_id],
      activity_stream_type_id: type_id,
      activity_stream_object_id: object_id,
      role_id: role_id,
      group_id: data[:group_id],
      created_at: data[:created_at],
      created_by_id: data[:created_by_id]
    }

    ActivityStream.create(record)
  end

=begin

remove whole activity entries of an object

  ActivityStream.remove('Ticket', 123)

=end

  def self.remove(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)
    ActivityStream.where(
      activity_stream_object_id: object_id,
      o_id: o_id,
    ).destroy_all
  end

=begin

return all activity entries of an user

  activity_stream = ActivityStream.list(user)

=end

  def self.list(user, limit)
    role_ids  = user.role_ids
    group_ids = user.group_ids

    # do not return an activity stream for custoers
    customer_role = Role.lookup(name: 'Customer')

    return [] if role_ids.include?(customer_role.id)
    stream = if group_ids.empty?
               ActivityStream.where('(role_id IN (?) AND group_id is NULL)', role_ids )
                             .order( 'created_at DESC, id DESC' )
                             .limit( limit )
             else
               ActivityStream.where('(role_id IN (?) AND group_id is NULL) OR ( role_id IN (?) AND group_id IN (?) ) OR ( role_id is NULL AND group_id IN (?) )', role_ids, role_ids, group_ids, group_ids )
                             .order( 'created_at DESC, id DESC' )
                             .limit( limit )
             end
    list = []
    stream.each do |item|
      data           = item.attributes
      data['object'] = ObjectLookup.by_id( data['activity_stream_object_id'] )
      data['type']   = TypeLookup.by_id( data['activity_stream_type_id'] )
      data.delete('activity_stream_object_id')
      data.delete('activity_stream_type_id')
      list.push data
    end
    list
  end

=begin

cleanup old stream messages

  ActivityStream.cleanup

optional you can parse the max oldest stream entries

  ActivityStream.cleanup(3.months)

=end

  def self.cleanup(diff = 3.months)
    ActivityStream.where('created_at < ?', Time.zone.now - diff).delete_all
    true
  end

end
