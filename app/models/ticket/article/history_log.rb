# Copyright (C) 2012-2013 Zammad Foundation, httpdata[://zammad-foundation.org/

module Ticket::Article::HistoryLog

=begin

create log activity for this article

  article = Ticket::Article.find(123)
  result = article.history_create( 'created', user_id )

returns

  result = true # false

=end

  def history_create (type, user_id, data = {})

    # if Ticketdata[:data[:Article has changed, remember related ticket to be able
    # to show article changes in ticket history
    data[:o_id]                   = self['id']
    data[:history_type]           = type
    data[:history_object]         = self.class.name
    data[:related_o_id]           = self['ticket_id']
    data[:related_history_object] = 'Ticket'
    data[:created_by_id]          = user_id
    History.add(data)
  end

=begin

get log activity for this article

  article = Ticket::Article.find(123)
  result = article.history_get()

returns

  result = [
    {
      :history_type      => 'created',
      :history_object    => 'Ticket::Article',
      :created_by_id     => 3,
      :created_at        => "2013-08-19 20:41:33",
    },
    {
      :history_type      => 'updated',
      :history_object    => 'Ticket::Article',
      :history_attribute => 'from',
      :o_id              => 1,
      :id_to             => nil,
      :id_from           => nil,
      :value_from        => "Some Body",
      :value_to          => "Some Body Else",
      :created_by_id     => 3,
      :created_at        => "2013-08-19 20:41:33",
    },
  ]

=end

  def history_get
    History.list( self.class.name, self['id'] )
  end

end