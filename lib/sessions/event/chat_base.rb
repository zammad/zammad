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

  def broadcast_agent_state_update(ignore_user_id = nil)

    # send broadcast to agents
    Chat::Agent.where(active: true).each {|item|
      next if item.updated_by_id == ignore_user_id
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

  def agent_permission_check
    if !@session
      error = {
        event: 'chat_error',
        data: {
          state: 'no_session',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    if !@session['id']
      error = {
        event: 'chat_error',
        data: {
          state: 'no_session_user_id',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    user = User.lookup(id: @session['id'])
    if !user
      error = {
        event: 'chat_error',
        data: {
          state: 'no_such_user',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    if !user.role?('Agent')
      error = {
        event: 'chat_error',
        data: {
          state: 'no_permission',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    true
  end

  def current_chat_session
    Chat::Session.find_by(session_id: @data['data']['session_id'])
  end

  def check_chat_session_exists
    if !@data['data'] || !@data['data']['session_id']
      error = {
        event: 'chat_error',
        data: {
          state: 'Need session_id.',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    return true if current_chat_session
    error = {
      event: 'chat_error',
      data: {
        state: "No such session id #{@data['data']['session_id']}",
      },
    }
    Sessions.send(@client_id, error)
    false
  end

  def current_chat
    Chat.find_by(id: @data['data']['chat_id'])
  end

  def check_chat_exists
    chat = current_chat
    return true if chat
    error = {
      event: 'chat_error',
      data: {
        state: 'no_such_chat',
      },
    }
    Sessions.send(@client_id, error)
    false
  end

end
