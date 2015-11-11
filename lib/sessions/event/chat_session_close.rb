class Sessions::Event::ChatSessionClose < Sessions::Event::ChatBase

  def run

    if !@data['data'] || !@data['data']['session_id']
      return {
        event: 'chat_status_close',
        data: {
          state: 'Need session_id.',
        },
      }
    end

    chat_session = Chat::Session.find_by(session_id: @data['data']['session_id'])
    if !chat_session
      return {
        event: 'chat_status_close',
        data: {
          state: "No such session id #{@data['data']['session_id']}",
        },
      }
    end

    realname = 'anonymous'
    if @session && @session['id']
      realname = User.find(@session['id']).fullname
    end

    # notify about "leaving"
    if @session && chat_session.user_id == @session['id']
      message = {
        event: 'chat_session_closed',
        data: {
          session_id: chat_session.session_id,
          realname: realname,
        },
      }

      # close session if host is closing it
      chat_session.state = 'closed'
      chat_session.save
    else
      message = {
        event: 'chat_session_left',
        data: {
          session_id: chat_session.session_id,
          realname: realname,
        },
      }
    end
    chat_session.send_to_recipients(message, @client_id)

    # notifiy participients
    {
      event: 'chat_status_close',
      data: {
        state: 'ok',
        session_id: chat_session.session_id,
      },
    }
  end
end
