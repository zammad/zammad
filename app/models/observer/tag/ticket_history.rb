# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'history'

class Observer::Tag::TicketHistory < ActiveRecord::Observer
  observe 'tag'

  def after_create(record)

    # just process ticket object tags
    return true if record.tag_object.name != 'Ticket';

    # add ticket history
    History.history_create(
      :o_id                   => record.o_id,
      :history_type           => 'added',
      :history_object         => 'Ticket',
      :history_attribute      => 'Tag',
      :value_from             => record.tag_item.name,
      :created_by_id          => record.created_by_id || UserInfo.current_user_id || 1
    )
  end
  def after_destroy(record)

    # just process ticket object tags
    return true if record.tag_object.name != 'Ticket';

    # add ticket history
    History.history_create(
      :o_id                   => record.o_id,
      :history_type           => 'removed',
      :history_object         => 'Ticket',
      :history_attribute      => 'Tag',
      :value_from             => record.tag_item.name,
      :created_by_id          => record.created_by_id || UserInfo.current_user_id || 1
    )
  end
end
