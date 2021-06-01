# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class History < ApplicationModel
  include CanBeImported
  include History::Assets

  self.table_name = 'histories'

  belongs_to :history_type,      class_name: 'History::Type', optional: true
  belongs_to :history_object,    class_name: 'History::Object', optional: true
  belongs_to :history_attribute, class_name: 'History::Attribute', optional: true

  # the noop is needed since Layout/EmptyLines detects
  # the block commend below wrongly as the measurement of
  # the wanted indentation of the rubocop re-enabling above
  def noop; end

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
    if data[:history_type].present?
      history_type = type_lookup(data[:history_type])
    end
    if data[:history_object].present?
      history_object = object_lookup(data[:history_object])
    end
    related_history_object_id = nil
    if data[:related_history_object].present?
      related_history_object = object_lookup(data[:related_history_object])
      related_history_object_id = related_history_object.id
    end
    history_attribute_id = nil
    if data[:history_attribute].present?
      history_attribute = attribute_lookup(data[:history_attribute])
      history_attribute_id = history_attribute.id
    end

    # create history
    record = {
      id:                        data[:id],
      o_id:                      data[:o_id],
      history_type_id:           history_type.id,
      history_object_id:         history_object.id,
      history_attribute_id:      history_attribute_id,
      related_history_object_id: related_history_object_id,
      related_o_id:              data[:related_o_id],
      value_from:                data[:value_from],
      value_to:                  data[:value_to],
      id_from:                   data[:id_from],
      id_to:                     data[:id_to],
      created_at:                data[:created_at],
      created_by_id:             data[:created_by_id]
    }
    history_record = nil
    if data[:id]
      history_record = History.find_by(id: data[:id])
    end
    if history_record
      history_record.update!(record)
    else
      record_new = History.create!(record)
      if record[:id]
        record_new.id = record[:id]
      end
      record_new.save!
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
      o_id:              requested_object_id,
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

  history_list = History.list('Ticket', 123, 'Ticket::Article')

returns

  history_list = [
    { ... },
    { ... },
    { ... },
    { ... },
  ]

return all history entries of an object and it's assets

  history = History.list('Ticket', 123, nil, ['Ticket::Article'])

returns

  history = {
    list: list,
    assets: assets,
  }

=end

  def self.list(requested_object, requested_object_id, related_history_object = [], assets = nil)
    histories = History.where(
      history_object_id: object_lookup(requested_object).id,
      o_id:              requested_object_id
    )

    if related_history_object.present?
      object_ids = []
      Array(related_history_object).each do |object|
        object_ids << object_lookup(object).id
      end

      histories = histories.or(
        History.where(
          history_object_id: object_ids,
          related_o_id:      requested_object_id
        )
      )
    end

    histories = histories.order(:created_at, :id)

    list = histories.map(&:attributes).each do |data|
      data['object'] = History::Object.lookup(id: data.delete('history_object_id'))&.name
      data['type']   = History::Type.lookup(id: data.delete('history_type_id'))&.name

      if data['history_attribute_id']
        data['attribute'] = History::Attribute.lookup(id: data.delete('history_attribute_id'))&.name
      end

      if data['related_history_object_id']
        data['related_object'] = History::Object.lookup(id: data.delete('related_history_object_id'))&.name
      end

      data.delete('updated_at')
      data.delete('related_o_id') if data['related_o_id'].nil?

      if data['id_to'].nil? && data['id_from'].nil?
        data.delete('id_from')
        data.delete('id_to')
      end

      if data['value_to'].nil? && data['value_from'].nil?
        data.delete('value_from')
        data.delete('value_to')
      end
    end

    return list if !assets

    {
      list:   list,
      assets: histories.reduce({}) { |memo, obj| obj.assets(memo) }
    }
  end

  def self.type_lookup(name)
    # lookup
    history_type = History::Type.lookup(name: name)
    return history_type if history_type

    # create
    History::Type.create!(name: name)
  end

  def self.object_lookup(name)
    # lookup
    history_object = History::Object.lookup(name: name)
    return history_object if history_object

    # create
    History::Object.create!(name: name)
  end

  def self.attribute_lookup(name)
    # lookup
    history_attribute = History::Attribute.lookup(name: name)
    return history_attribute if history_attribute

    # create
    History::Attribute.create!(name: name)
  end
end
