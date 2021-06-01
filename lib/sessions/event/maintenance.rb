# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::Maintenance < Sessions::Event::Base
  database_connection_required

=begin

Event module to broadcast maintenance messages to all client connections.

To execute this manually, just paste the following into the browser console

  App.WebSocket.send({event:'maintenance', data: {some: 'key'}})

=end

  def run

    # check if sender is admin
    return if !permission_check('admin.maintenance', 'maintenance')

    Sessions.broadcast(@payload, 'public', @session['id'])
    false
  end

end
