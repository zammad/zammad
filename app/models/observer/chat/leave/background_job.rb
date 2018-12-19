class Observer::Chat::Leave::BackgroundJob
  def initialize(chat_session_id, client_id, session)
    @chat_session_id = chat_session_id
    @client_id = client_id
    @session = session
  end

  def perform

    # check if customer has permanently left the conversation
    chat_session = Chat::Session.find_by(id: @chat_session_id)
    return if !chat_session
    return if chat_session.recipients_active?

    chat_session.state = 'closed'
    chat_session.save

    realname = 'Anonymous'
    if @session && @session['id']
      realname = User.lookup(id: @session['id']).fullname
    end

    # notify participants
    message = {
      event: 'chat_session_left',
      data:  {
        realname:   realname,
        session_id: chat_session.session_id,
      },
    }
    chat_session.send_to_recipients(message, @client_id)

    Chat.broadcast_agent_state_update
  end

end
