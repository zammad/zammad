# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection
  def session( collections, user )

    # all ticket stuff
    collections[ Ticket::StateType.to_online_model ]       = Ticket::StateType.all
    collections[ Ticket::State.to_online_model ]           = Ticket::State.all
    collections[ Ticket::Priority.to_online_model ]        = Ticket::Priority.all
    collections[ Ticket::Article::Type.to_online_model ]   = Ticket::Article::Type.all
    collections[ Ticket::Article::Sender.to_online_model ] = Ticket::Article::Sender.all

    if !user.is_role('Customer')

      # all signatures
      collections[ Signature.to_online_model ]     = Signature.all

      # all email addresses
      collections[ EmailAddress.to_online_model ]  = EmailAddress.all
    end
  end
  def push( collections, user )

    # all ticket stuff
    collections[ Ticket::StateType.to_online_model ]       = Ticket::StateType.all
    collections[ Ticket::State.to_online_model ]           = Ticket::State.all
    collections[ Ticket::Priority.to_online_model ]        = Ticket::Priority.all
    collections[ Ticket::Article::Type.to_online_model ]   = Ticket::Article::Type.all
    collections[ Ticket::Article::Sender.to_online_model ] = Ticket::Article::Sender.all

    if !user.is_role('Customer')

      # all signatures
      collections[ Signature.to_online_model ]     = Signature.all

      # all email addresses
      collections[ EmailAddress.to_online_model ]  = EmailAddress.all
    end
  end

  module_function :session, :push
end
