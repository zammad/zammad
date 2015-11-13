class Sessions::Event::ChatBase

  def initialize(data, session, client_id)
    @data = data
    @session = session
    @client_id = client_id
  end

  def pre

    # check if feature is enabled
    return if Setting.get('chat')
    {
      event: 'chat_error',
      data: {
        state: 'chat_disabled',
      },
    }
  end

  def post
    false
  end

  def broadcast_agent_state_update

    # send broadcast to agents
    Chat::Agent.where(active: true).each {|item|
      data = {
        event: 'chat_status_agent',
        data: Chat.agent_state(item.updated_by_id),
      }
      Sessions.send_to(item.updated_by_id, data)
    }
  end

  def broadcast_customer_state_update

    # send position update to other waiting sessions
    position = 0
    Chat::Session.where(state: 'waiting').order('created_at ASC').each {|local_chat_session|
      position += 1
      data = {
        event: 'chat_session_queue',
        data: {
          state: 'queue',
          position: position,
          session_id: local_chat_session.session_id,
        },
      }
      local_chat_session.send_to_recipients(data)
    }
  end

end
