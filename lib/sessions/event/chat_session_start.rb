class Sessions::Event::ChatSessionStart

  def self.run(data, session, client_id)

    # check if feature is enabled
    if !Setting.get('chat')
      return {
        event: 'chat_session_start',
        data: {
          state: 'chat_disabled',
        },
      }
    end

    # find first in waiting list
    chat_session = Chat::Session.where(state: 'waiting').order('created_at ASC').first
    if !chat_session
      return {
        event: 'chat_session_start',
        data: {
          state: 'failed',
          message: 'No session available.',
        },
      }
    end
    chat_session.user_id = session['id']
    chat_session.state = 'running'
    chat_session.preferences[:participants].push client_id
    chat_session.save

    # send chat_session_init to client
    chat_user = User.find(chat_session.user_id)
    user = {
      name: chat_user.fullname,
      avatar: chat_user.image,
    }
    data = {
      event: 'chat_session_start',
      data: {
        state: 'ok',
        agent: user,
        session_id: chat_session.session_id,
      },
    }

    chat_session.preferences[:participants].each {|local_client_id|
      next if local_client_id == client_id
      Sessions.send(local_client_id, data)
    }

    # send chat_session_init to agent
    {
      event: 'chat_session_start',
      data: {
        state: 'ok',
        session: chat_session,
      },
    }
  end
end
