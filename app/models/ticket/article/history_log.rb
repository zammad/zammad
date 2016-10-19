# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Article::HistoryLog

=begin

create log activity for this article

  article = Ticket::Article.find(123)
  result = article.history_create( 'created', user_id )

returns

  result = true # false

=end

  def history_log (type, user_id, data = {})

    # if Ticketdata[:data[:Article has changed, remember related ticket to be able
    # to show article changes in ticket history
    data[:o_id]                   = self['id']
    data[:history_type]           = type
    data[:history_object]         = self.class.name
    data[:related_o_id]           = self['ticket_id']
    data[:related_history_object] = 'Ticket'
    data[:created_by_id]          = user_id
    data[:updated_at]             = updated_at
    data[:created_at]             = updated_at
    History.add(data)
  end
end
