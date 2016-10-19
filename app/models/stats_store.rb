# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class StatsStore < ApplicationModel
  store :data

=begin

  count = StatsStore.count_by_search(
    object: 'User',
    o_id: ticket.owner_id,
    key: 'ticket:reopen',
    start:  Time.zone.now - 7.days,
    end:    Time.zone.now,
  )

=end

  def self.count_by_search(data)

    # lookups
    if data[:object]
      object_id = ObjectLookup.by_name( data[:object] )
    end

    StatsStore.where(stats_store_object_id: object_id, o_id: data[:o_id], key: data[:key])
              .where('created_at > ? AND created_at < ?', data[:start], data[:end]).count
  end

=begin

  item = StatsStore.search(
    object: 'User',
    o_id: current_user.id,
    key: 'dashboard',
  )

=end

  def self.search(data)

    # lookups
    if data[:object]
      data[:stats_store_object_id] = ObjectLookup.by_name( data[:object] )
      data.delete(:object)
    end

    find_by(data)
  end

=begin

  item = StatsStore.sync(
    object: 'User',
    o_id: current_user.id,
    key: 'dashboard',
    data: {some data},
  )

=end

  def self.sync(params)

    data = params[:data]
    params.delete(:data)

    item = search(params)

    if item
      item.data = data
      item.save
      return item
    end

    # lookups
    if data[:object]
      data[:stats_store_object_id] = ObjectLookup.by_name( data[:object] )
      data.delete(:object)
    end

    params[:data] = data
    params[:created_by_id] = 1
    create(params)
  end

=begin

  StatsStore.add(
    object: 'User',
    o_id: ticket.owner_id,
    key: 'ticket:reopen',
    data: { ticket_id: ticket.id },
    created_at: Time.zone.now,
  )

=end

  def self.add(data)

    # lookups
    if data[:object]
      object_id = ObjectLookup.by_name( data[:object] )
    end

    # create history
    record = {
      stats_store_object_id: object_id,
      o_id: data[:o_id],
      key: data[:key],
      data: data[:data],
      created_at: data[:created_at],
      created_by_id: data[:created_by_id],
    }

    StatsStore.create(record)
  end

=begin

cleanup old stats store

  StatsStore.cleanup

optional you can put the max oldest stats store entries as argument

  StatsStore.cleanup(3.months)

=end

  def self.cleanup(diff = 3.months)
    StatsStore.where('updated_at < ?', Time.zone.now - diff).delete_all
    true
  end

end
