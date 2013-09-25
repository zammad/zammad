# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module Ticket::HistoryLog

=begin

create log activity for this ticket

  ticket = Ticket.find(123)
  result = ticket.history_create( 'created', user_id )

returns

  result = true # false

=end

  def history_create (type, user_id, data = {})

    data[:o_id]                   = self['id']
    data[:history_type]           = type
    data[:history_object]         = self.class.name
    data[:related_o_id]           = nil
    data[:related_history_object] = nil
    data[:created_by_id]          = user_id
    History.add(data)
  end

=begin

get log activity for this ticket

  ticket = Ticket.find(123)
  result = ticket.history_get()

returns

  result = [
    {
      :history_type      => 'created',
      :history_object    => 'Ticket',
      :created_by_id     => 3,
      :created_at        => "2013-08-19 20:41:33",
    },
    {
      :history_type      => 'updated',
      :history_object    => 'Ticket',
      :history_attribute => 'ticket_priority',
      :o_id              => 1,
      :id_to             => 3,
      :id_from           => 2,
      :value_from        => "low",
      :value_to          => "high",
      :created_by_id     => 3,
      :created_at        => "2013-08-19 20:41:33",
    },
  ]

=end

  def history_get
    History.list( self.class.name, self['id'], 'Ticket::Article' )
  end

end