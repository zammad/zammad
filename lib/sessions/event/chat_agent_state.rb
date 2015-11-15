class Sessions::Event::ChatAgentState < Sessions::Event::ChatBase

  def run

    # only agents can do this
    chat_id = 1
    chat = Chat.find_by(id: chat_id)
    if !@session['id']
      return {
        event: 'chat_agent_state',
        data: {
          state: 'failed',
          message: 'No such user_id.'
        },
      }
    end

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
