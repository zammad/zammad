# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::SessionTakeover < Sessions::Event::Base
  database_connection_required

  def run
    return if !valid_session?

    Sessions.send_to(@session['id'], {
                       event: 'session_takeover',
                       data:  @payload['data'],
                     })
  end

end
