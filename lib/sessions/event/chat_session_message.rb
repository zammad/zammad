class Sessions::Event::ChatSessionMessage < Sessions::Event::ChatBase

  def run

    if !@data['data'] || !@data['data']['session_id']
      return {
        event: 'chat_session_message',
        data: {
          state: 'Need session_id.',
        },
      }
    end

    chat_session = Chat::Session.find_by(session_id: @data['data']['session_id'])
    if !chat_session
      return {
        event: 'chat_session_message',
        data: {
          state: "No such session id #{data['data']['session_id']}",
        },
      }
    end

    user_id = nil
    if @session
      user_id = @session['id']
    end
    chat_message = Chat::Message.create(
      chat_session_id: chat_session.id,
      content: @data['data']['content'],
      created_by_id: user_id,
    )
    message = {
      event: 'chat_session_message',
      data: {
        session_id: chat_session.session_id,
        message: chat_message,
      },
    }

    # send to participents
    chat_session.send_to_recipients(message, @client_id)

    # send chat_session_init to agent
    {
      event: 'chat_session_message',
      data: {
        session_id: chat_session.session_id,
        message: chat_message,
        self_written: true,
      },
    }

  end
end
