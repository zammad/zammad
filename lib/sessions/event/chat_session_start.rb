class Sessions::Event::ChatSessionStart < Sessions::Event::ChatBase

  def run
    return super if super
    return if !permission_check('chat.agent', 'chat')

    # find first in waiting list
    chat_session = Chat::Session.where(state: 'waiting').order(created_at: :asc).first
    if !chat_session
      return {
        event: 'chat_session_start',
        data:  {
          state:   'failed',
          message: 'No session available.',
        },
      }
    end
    chat_session.user_id = @session['id']
    chat_session.state = 'running'
    chat_session.preferences[:participants] = chat_session.add_recipient(@client_id)
    chat_session.save

    # send chat_session_init to client
    chat_user = User.lookup(id: chat_session.user_id)
    url = nil
    if chat_user.image && chat_user.image != 'none'
      url = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/api/v1/users/image/#{chat_user.image}"
    end
    user = {
      name:   chat_user.fullname,
      avatar: url,
    }
    data = {
      event: 'chat_session_start',
      data:  {
        state:      'ok',
        agent:      user,
        session_id: chat_session.session_id,
        chat_id:    chat_session.chat_id,
      },
    }
    # send to customer
    chat_session.send_to_recipients(data, @client_id)

    # send to agent
    data = {
      event: 'chat_session_start',
      data:  {
        session: chat_session.attributes,
      },
    }
    Sessions.send(@client_id, data)

    # send state update with sessions to agents
    Chat.broadcast_agent_state_update

    # send position update to other waiting sessions
    Chat.broadcast_customer_state_update

    nil
  end

end
