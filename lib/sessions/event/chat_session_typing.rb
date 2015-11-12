class Sessions::Event::ChatSessionTyping < Sessions::Event::ChatBase

  def run

    if !@data['data'] || !@data['data']['session_id']
      return {
        event: 'chat_session_typing',
        data: {
          state: 'Need session_id.',
        },
      }
    end

    chat_session = Chat::Session.find_by(session_id: @data['data']['session_id'])
    if !chat_session
      return {
        event: 'chat_session_typing',
        data: {
          state: "No such session id #{@data['data']['session_id']}",
        },
      }
    end

    user_id = nil
    if @session
      user_id = @session['id']
    end
    message = {
      event: 'chat_session_typing',
      data: {
        session_id: chat_session.session_id,
        user_id: user_id,
      },
    }

    # send to participents
    chat_session.send_to_recipients(message, @client_id)

    # send chat_session_init to agent
    {
      event: 'chat_session_typing',
      data: {
        session_id: chat_session.session_id,
        self_written: true,
      },
    }
  end
end
