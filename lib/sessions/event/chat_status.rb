class Sessions::Event::ChatStatus

  def self.run(_data, _session, _client_id)

    # check if feature is enabled
    if !Setting.get('chat')
      return {
        event: 'chat_status',
        data: {
          state: 'chat_disabled',
        },
      }
    end

    chat_id = 1
    chat = Chat.find_by(id: chat_id)
    if !chat
      return {
        event: 'chat_status',
        data: {
          state: 'no_such_chat',
        },
      }
    end

    {
      event: 'chat_status',
      data: chat.state,
    }
  end
end
