class Sessions::Event::ChatSessionTyping < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    user_id = nil
    if @session
      user_id = @session['id']
    end
    message = {
      event: 'chat_session_typing',
      data:  {
        session_id: chat_session.session_id,
        user_id:    user_id,
      },
    }

    # send to participents
    chat_session.send_to_recipients(message, @client_id)

    # send chat_session_init to agent
    {
      event: 'chat_session_typing',
      data:  {
        session_id:   chat_session.session_id,
        self_written: true,
      },
    }
  end

end
