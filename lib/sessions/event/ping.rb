# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::Ping < Sessions::Event::Base

=begin

Event module to send pong to client connection.

To execute this manually, just paste the following into the browser console

  App.WebSocket.send({event:'ping'})

=end

  def run
    {
      event: 'pong',
    }
  end

end
