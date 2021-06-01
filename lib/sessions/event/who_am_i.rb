# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::WhoAmI < Sessions::Event::Base
  database_connection_required

=begin

Event module to send `who am i` to client connection.

To execute this manually, just paste the following into the browser console

  App.WebSocket.send({event:'who_am_i'})

=end

  def run

    if !@session || !@session['id']
      return {
        event: 'who_am_i',
        data:  {
          message: 'session not authenticated',
        },
      }
    end

    user = User.find_by(id: @session['id'])

    if !user
      return {
        event: 'who_am_i',
        data:  {
          message: "No such user with id #{@session['id']}",
        },
      }
    end
    attributes = user.attributes
    attributes.delete('password')
    {
      event: 'who_am_i',
      data:  {
        message: 'session authenticated',
        user:    attributes,
      },
    }
  end

end
