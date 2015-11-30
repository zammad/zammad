class Sessions::Event::ChatAgentState < Sessions::Event::ChatBase

  def run

    # check if user has permissions
    return if !agent_permission_check

    Chat::Agent.state(@session['id'], @data['data']['active'])

    # broadcast new state to agents
    broadcast_agent_state_update(@session['id'])

    {
      event: 'chat_agent_state',
      data: {
        state: 'ok',
        active: @data['data']['active'],
      },
    }
  end
end
