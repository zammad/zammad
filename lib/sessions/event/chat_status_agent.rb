class Sessions::Event::ChatStatusAgent

  def self.run(_data, session, _client_id)

    # check if user has permissions

    # check if feature is enabled
    if !Setting.get('chat')
      return {
        event: 'chat_status_agent',
        data: {
          state: 'chat_disabled',
        },
      }
    end

    # renew timestamps
    state = Chat::Agent.state(session['id'])
    Chat::Agent.state(session['id'], state)

    {
      event: 'chat_status_agent',
      data: Chat.agent_state(session['id']),
    }
  end

end
