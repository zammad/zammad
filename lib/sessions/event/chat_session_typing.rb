class Sessions::Event::ChatSessionTyping

  def self.run(data, session, client_id)

    # check if feature is enabled
    if !Setting.get('chat')
      return {
        event: 'chat_session_typing',
        data: {
          state: 'chat_disabled',
        },
      }
    end

    if !data['data'] || !data['data']['session_id']
      return {
        event: 'chat_session_typing',
        data: {
          state: 'Need session_id.',
        },
      }
    end

    chat_session = Chat::Session.find_by(session_id: data['data']['session_id'])
    if !chat_session
      return {
        event: 'chat_session_typing',
        data: {
          state: "No such session id #{data['data']['session_id']}",
        },
      }
    end

    user_id = nil
    if session
      user_id = session['id']
    end
    message = {
      event: 'chat_session_typing',
      data: {
        session_id: chat_session.session_id,
        user_id: user_id,
      },
    }

    # send to participents
    chat_session.preferences[:participants].each {|local_client_id|
      next if local_client_id == client_id
      Sessions.send(local_client_id, message)
    }

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
