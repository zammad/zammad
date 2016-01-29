# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
module Ticket::HistoryLog

=begin

create log activity for this ticket

  ticket = Ticket.find(123)
  result = ticket.history_create('created', user_id)

returns

  result = true # false

=end

  def history_log (type, user_id, data = {})
    data[:o_id]                   = self['id']
    data[:history_type]           = type
    data[:history_object]         = self.class.name
    data[:related_o_id]           = nil
    data[:related_history_object] = nil
    data[:created_by_id]          = user_id
    data[:updated_at]             = updated_at
    data[:created_at]             = updated_at
    History.add(data)
  end

=begin

get log activity for this ticket

  ticket = Ticket.find(123)
  result = ticket.history_get()

returns

  result = [
    {
      type: 'created',
      object: 'Ticket',
      created_by_id: 3,
      created_at: "2013-08-19 20:41:33",
    },
    {
      type: 'updated',
      object: 'Ticket',
      attribute: 'priority',
      o_id: 1,
      id_to: 3,
      id_from: 2,
      value_from: "low",
      value_to: "high",
      created_by_id: 3,
      created_at: "2013-08-19 20:41:33",
    },
  ]

=end

  def history_get(fulldata = false)
    list = History.list(self.class.name, self['id'], 'Ticket::Article')
    return list if !fulldata

    # get related objects
    assets = {}
    list.each {|item|
      record = Kernel.const_get(item['object']).find(item['o_id'])
      assets = record.assets(assets)

      if item['related_object']
        record = Kernel.const_get(item['related_object']).find( item['related_o_id'])
        assets = record.assets(assets)
      end
    }
    {
      history: list,
      assets: assets,
    }
  end
end
