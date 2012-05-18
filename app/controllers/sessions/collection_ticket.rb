module ExtraCollection
  def add(collections)

    collections['TicketStateType']     = Ticket::StateType.all
    collections['TicketState']         = Ticket::State.all
    collections['TicketPriority']      = Ticket::Priority.all
    collections['TicketArticleType']   = Ticket::Article::Type.all
    collections['TicketArticleSender'] = Ticket::Article::Sender.all

  end
  module_function :add
end