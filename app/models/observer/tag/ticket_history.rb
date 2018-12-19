# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Observer::Tag::TicketHistory < ActiveRecord::Observer
  observe 'tag'

  def after_create(record)

    # just process ticket object tags
    return true if record.tag_object.name != 'Ticket'

    # add ticket history
    History.add(
      o_id:              record.o_id,
      history_type:      'added',
      history_object:    'Ticket',
      history_attribute: 'tag',
      value_to:          record.tag_item.name,
      created_by_id:     record.created_by_id,
    )
  end

  def after_destroy(record)

    # just process ticket object tags
    return true if record.tag_object.name != 'Ticket'

    # add ticket history
    History.add(
      o_id:              record.o_id,
      history_type:      'removed',
      history_object:    'Ticket',
      history_attribute: 'tag',
      value_to:          record.tag_item.name,
      created_by_id:     record.created_by_id,
    )
  end
end
