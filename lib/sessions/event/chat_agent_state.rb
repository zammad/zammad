class Sessions::Event::ChatAgentState

  def self.run(data, session, _client_id)

    # check if feature is enabled
    if !Setting.get('chat')
      return {
        event: 'chat_agent_state',
        data: {
          state: 'chat_disabled',
        },
      }
    end

    # only agents can do this
    chat_id = 1
    chat = Chat.find_by(id: chat_id)
    if !session['id']
      return {
        event: 'chat_agent_state',
        data: {
          state: 'failed',
          message: 'No such user_id.'
        },
      }
    end

    Chat::Agent.state(session['id'], data['data']['active'])

    {
      event: 'chat_agent_state',
      data: {
        state: 'ok',
        active: data['data']['active'],
      },
    }
  end
end
