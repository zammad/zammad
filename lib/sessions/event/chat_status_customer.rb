# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::ChatStatusCustomer < Sessions::Event::ChatBase

=begin

a customer requests the current state of a chat

payload

  {
    event: 'chat_status_agent',
    data: {
      session_id: 'the id of the current chat session',
      url: 'optional url', # will trigger a chat_session_notice to agent
    },
  }

return is sent as message back to peer

=end

  def run
    return super if super
    return if !check_chat_exists
    return if blocked_ip?
    return if blocked_country?
    return if blocked_origin?

    # check if it's a chat sessin reconnect
    session_id = nil
    if @payload['data']['session_id']
      session_id = @payload['data']['session_id']

      # update recipients of existing sessions
      chat_session = Chat::Session.find_by(session_id: session_id)
      if chat_session
        chat_session.add_recipient(@client_id, true)

        # sent url update to agent
        if @payload['data']['url']
          message = {
            event: 'chat_session_notice',
            data:  {
              session_id: chat_session.session_id,
              message:    @payload['data']['url'],
            },
          }
          chat_session.send_to_recipients(message, @client_id)
        end
      end
    end

    {
      event: 'chat_status_customer',
      data:  current_chat.customer_state(session_id),
    }
  end

  def blocked_ip?
    return false if !current_chat.blocked_ip?(remote_ip)

    send_unavailable
    true
  end

  def blocked_country?
    return false if !current_chat.blocked_country?(remote_ip)

    send_unavailable
    true
  end

  def blocked_origin?
    return false if current_chat.website_whitelisted?(origin)

    send_unavailable
    true
  end

  def send_unavailable
    error = {
      event: 'chat_error',
      data:  {
        state: 'chat_unavailable',
      },
    }
    Sessions.send(@client_id, error)
  end
end
