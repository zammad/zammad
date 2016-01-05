class Sessions::Event::ChatSessionInit < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_exists

    # geo ip lookup
    geo_ip = nil
    if @remote_ip
      geo_ip = Service::GeoIp.location(@remote_ip)
    end

    # create chat session
    chat_session = Chat::Session.create(
      chat_id: @payload['data']['chat_id'],
      name: '',
      state: 'waiting',
      preferences: {
        participants: [@client_id],
        remote_ip: @remote_ip,
        geo_ip: geo_ip,
      },
    )

    # send broadcast to agents
    broadcast_agent_state_update

    # return new session
    {
      event: 'chat_session_queue',
      data: {
        state: 'queue',
        position: Chat.waiting_chat_count,
        session_id: chat_session.session_id,
      },
    }
  end

end
