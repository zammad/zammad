# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::ChatSessionClose < Sessions::Event::ChatBase

=begin

a agent or customer is closing the chat session

payload

  {
    event: 'chat_session_close',
    data: {},
  }

return is sent as message back to peer

=end

  def run
    return super if super

    return if !check_chat_session_exists

    realname = 'Anonymous'

    # if it is a agent session, use the realname if the agent for close message
    chat_session = current_chat_session
    if @session && @session['id'] && chat_session.user_id
      agent_user = chat_session.agent_user
      if agent_user[:name]
        realname = agent_user[:name]
      end
    end

    # check count of participents
    participents_count = 0
    if chat_session.preferences[:participents]
      participents_count = chat_session.preferences[:participents].count
    end

    # notify about "closing"
    if participents_count < 2 || (@session && chat_session.user_id == @session['id'])
      message = {
        event: 'chat_session_closed',
        data:  {
          session_id: chat_session.session_id,
          realname:   realname,
        },
      }

      # close session if host is closing it
      chat_session.state = 'closed'
      chat_session.save

      # set state update to all agents
      Chat.broadcast_agent_state_update([chat_session.chat_id])

      # send position update to other waiting sessions
      Chat.broadcast_customer_state_update(chat_session.chat_id)

    # notify about "leaving"
    else
      message = {
        event: 'chat_session_left',
        data:  {
          session_id: chat_session.session_id,
          realname:   realname,
        },
      }
    end
    chat_session.send_to_recipients(message, @client_id)

    # notifiy participients
    {
      event: 'chat_status_close',
      data:  {
        state:      'ok',
        session_id: chat_session.session_id,
      },
    }
  end

end
