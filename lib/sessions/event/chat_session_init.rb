class Sessions::Event::ChatSessionInit < Sessions::Event::ChatBase

  def run

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
        participants: [@client_id],
      },
    )

    # send broadcast to agents
    broadcast_agent_state_update

    # return new session
    {
      event: 'chat_session_queue',
      data: {
        state: 'queue',
        position: Chat.waiting_chat_count,
        session_id: chat_session.session_id,
      },
    }
  end
end
