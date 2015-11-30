class Sessions::Event::ChatStatusAgent < Sessions::Event::ChatBase

  def run

    # check if user has permissions
    return if !agent_permission_check

    # renew timestamps
    state = Chat::Agent.state(@session['id'])
    Chat::Agent.state(@session['id'], state)

    # update recipients of existing sessions
    Chat::Session.where(state: 'running', user_id: @session['id']).order('created_at ASC').each {|chat_session|
      chat_session.add_recipient(@client_id, true)
    }
    {
      event: 'chat_status_agent',
      data: Chat.agent_state(@session['id']),
    }
  end

end
