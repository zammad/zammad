module ExtraCollection
  def session( collections, user )

    # all ticket stuff
    collections['TicketStateType']     = Ticket::StateType.all
    collections['TicketState']         = Ticket::State.all
    collections['TicketPriority']      = Ticket::Priority.all
    collections['TicketArticleType']   = Ticket::Article::Type.all
    collections['TicketArticleSender'] = Ticket::Article::Sender.all

    # all signatures
    collections['Signature']           = Signature.all

    # all email addresses
    collections['EmailAddress']        = EmailAddress.all

  end
  def push( collections, user )

    # all ticket stuff
    collections['TicketStateType']     = Ticket::StateType.all
    collections['TicketState']         = Ticket::State.all
    collections['TicketPriority']      = Ticket::Priority.all
    collections['TicketArticleType']   = Ticket::Article::Type.all
    collections['TicketArticleSender'] = Ticket::Article::Sender.all

    # all signatures
    collections['Signature']           = Signature.all

    # all email addresses
    collections['EmailAddress']        = EmailAddress.all

    # all templates
    collections['Template']            = Template.all

    # all text modules
    collections['TextModule']          = TextModule.all

  end

  module_function :session, :push
end