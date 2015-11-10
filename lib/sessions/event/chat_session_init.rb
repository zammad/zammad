class Sessions::Event::ChatSessionInit

  def self.run(data, _session, client_id)

    # check if feature is enabled
    if !Setting.get('chat')
      return {
        event: 'chat_session_init',
        data: {
          state: 'chat_disabled',
        },
      }
    end

    chat_id = 1
    chat = Chat.find_by(id: chat_id)
    if !chat
      return {
        event: 'chat_session_init',
        data: {
          state: 'no_such_chat',
        },
      }
    end

    # create chat session
    chat_session = Chat::Session.create(
      chat_id: chat_id,
      name: '',
      state: 'waiting',
      preferences: {
        participants: [client_id],
      },
    )

    # send update to agents
    User.where(active: true).each {|user|
      data = {
        event: 'chat_status_agent',
        data: Chat.agent_state(user.id),
      }
      Sessions.send_to(user.id, data)
    }

    # return new session
    {
      event: 'chat_session_init',
      data: {
        state: 'queue',
        position: Chat.waiting_chat_count,
        session_id: chat_session.session_id,
      },
    }
  end
end
