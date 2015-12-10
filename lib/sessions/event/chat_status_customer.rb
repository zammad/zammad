class Sessions::Event::ChatStatusCustomer < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_exists

    # check if it's a chat sessin reconnect
    session_id = nil
    if @payload['data']['session_id']
      session_id = @payload['data']['session_id']

      # update recipients of existing sessions
      chat_session = Chat::Session.find_by(session_id: session_id)
      chat_session.add_recipient(@client_id, true)
    end
    {
      event: 'chat_status_customer',
      data: current_chat.customer_state(session_id),
    }
  end

end
