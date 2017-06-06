# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class History < ApplicationModel
  load 'history/assets.rb'
  include History::Assets

  self.table_name = 'histories'
  belongs_to :history_type,      class_name: 'History::Type'
  belongs_to :history_object,    class_name: 'History::Object'
  belongs_to :history_attribute, class_name: 'History::Attribute'

=begin

add a new history entry for an object

  History.add(
    history_type: 'updated',
    history_object: 'Ticket',
    history_attribute: 'state',
    o_id: ticket.id,
    id_to: 3,
    id_from: 2,
    value_from: 'open',
    value_to: 'pending reminder',
    created_by_id: 1,
    created_at: '2013-06-04 10:00:00',
    updated_at: '2013-06-04 10:00:00'
  )

=end

  def self.add(data)

    # return if we run import mode
    return if Setting.get('import_mode') && !data[:id]

    # lookups
    if data[:history_type]
      history_type = type_lookup(data[:history_type])
    end
    if data[:history_object]
      history_object = object_lookup(data[:history_object])
    end
    related_history_object_id = nil
    if data[:related_history_object]
      related_history_object = object_lookup(data[:related_history_object])
      related_history_object_id = related_history_object.id
    end
    history_attribute_id = nil
    if data[:history_attribute]
      history_attribute = attribute_lookup(data[:history_attribute])
      history_attribute_id = history_attribute.id
    end

    # create history
    record = {
      id: data[:id],
      o_id: data[:o_id],
      history_type_id: history_type.id,
      history_object_id: history_object.id,
      history_attribute_id: history_attribute_id,
      related_history_object_id: related_history_object_id,
      related_o_id: data[:related_o_id],
      value_from: data[:value_from],
      value_to: data[:value_to],
      id_from: data[:id_from],
      id_to: data[:id_to],
      created_at: data[:created_at],
      created_by_id: data[:created_by_id]
    }
    history_record = nil
    if data[:id]
      history_record = History.find_by(id: data[:id])
    end
    if history_record
      history_record.update_attributes(record)
    else
      record_new = History.create(record)
      if record[:id]
        record_new.id = record[:id]
      end
      record_new.save
    end
  end

=begin

remove whole history entries of an object

  History.remove('Ticket', 123)

=end

  def self.remove(requested_object, requested_object_id)
    history_object = History::Object.find_by(name: requested_object)
    return if !history_object
    History.where(
      history_object_id: history_object.id,
      o_id: requested_object_id,
    ).destroy_all
  end

=begin

return all history entries of an object

  history_list = History.list('Ticket', 123)

returns

  history_list = [
    { ... },
    { ... },
    { ... },
    { ... },
  ]

return all history entries of an object and it's related history objects

  history_list = History.list('Ticket', 123, true)

returns

  history_list = [
    { ... },
    { ... },
    { ... },
    { ... },
  ]

return all history entries of an object and it's assets

  history = History.list('Ticket', 123, nil, true)

returns

  history = {
    list: list,
    assets: assets,
  }

=end

  def self.list(requested_object, requested_object_id, related_history_object = nil, assets = nil)
    if !related_history_object
      history_object = object_lookup(requested_object)
      history = History.where(history_object_id: history_object.id)
                       .where(o_id: requested_object_id)
                       .order('created_at ASC, id ASC')
    else
      history_object_requested = object_lookup(requested_object)
      history_object_related   = object_lookup(related_history_object)
      history = History.where(
        '((history_object_id = ? AND o_id = ?) OR (history_object_id = ? AND related_o_id = ? ))',
        history_object_requested.id,
        requested_object_id,
        history_object_related.id,
        requested_object_id,
      )
                       .order('created_at ASC, id ASC')
    end
    asset_list = {}
    list = []
    history.each do |item|

      if assets
        asset_list = item.assets(asset_list)
      end

      data = item.attributes
      data['object']    = object_lookup_id(data['history_object_id']).name
      data['type']      = type_lookup_id(data['history_type_id']).name
      data.delete('history_object_id')
      data.delete('history_type_id')

      if data['history_attribute_id']
        data['attribute'] = attribute_lookup_id(data['history_attribute_id']).name
      end
      data.delete('history_attribute_id')

      data.delete('updated_at')
      if data['id_to'].nil? && data['id_from'].nil?
        data.delete('id_to')
        data.delete('id_from')
      end
      if data['value_to'].nil? && data['value_from'].nil?
        data.delete('value_to')
        data.delete('value_from')
      end
      if !data['related_history_object_id'].nil?
        data['related_object'] = object_lookup_id(data['related_history_object_id']).name
      end
      data.delete('related_history_object_id')

      if data['related_o_id'].nil?
        data.delete('related_o_id')
      end

      list.push data
    end
    if assets
      return {
        list: list,
        assets: asset_list,
      }
    end
    list
  end

  def self.type_lookup_id(id)
    History::Type.lookup(id: id)
  end

  def self.type_lookup(name)
    # lookup
    history_type = History::Type.lookup(name: name)
    if history_type
      return history_type
    end

    # create
    History::Type.create(
      name: name
    )
  end

  def self.object_lookup_id(id)
    History::Object.lookup(id: id)
  end

  def self.object_lookup(name)
    # lookup
    history_object = History::Object.lookup(name: name)
    if history_object
      return history_object
    end

    # create
    History::Object.create(
      name: name
    )
  end

  def self.attribute_lookup_id(id)
    History::Attribute.lookup(id: id)
  end

  def self.attribute_lookup(name)
    # lookup
    history_attribute = History::Attribute.lookup(name: name)
    if history_attribute
      return history_attribute
    end

    # create
    History::Attribute.create(
      name: name
    )
  end

  class Object < ApplicationModel
  end

  class Type < ApplicationModel
  end

  class Attribute < ApplicationModel
  end

end
