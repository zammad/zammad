# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::FollowUpCheck

  def self.run( _channel, mail )

    return if mail[ 'x-zammad-ticket-id'.to_sym ]

    # get ticket# from subject
    ticket = Ticket::Number.check( mail[:subject] )
    return if !ticket
    mail[ 'x-zammad-ticket-id'.to_sym ] = ticket.id
  end
end
