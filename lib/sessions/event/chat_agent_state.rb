class Sessions::Event::ChatAgentState < Sessions::Event::ChatBase

  def run
    return super if super

    # check if user has permissions
    return if !permission_check('chat.agent', 'chat')

    Chat::Agent.state(@session['id'], @payload['data']['active'])

    # broadcast new state to agents
    Chat.broadcast_agent_state_update(@session['id'])

    {
      event: 'chat_agent_state',
      data:  {
        state:  'ok',
        active: @payload['data']['active'],
      },
    }
  end

end
