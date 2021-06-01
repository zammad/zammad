# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ChatLeaveJob < ApplicationJob
  def perform(chat_session_id, client_id, session)

    # check if customer has permanently left the conversation
    chat_session = Chat::Session.find_by(id: chat_session_id)
    return if !chat_session
    return if chat_session.recipients_active?

    chat_session.state = 'closed'
    chat_session.save

    realname = 'Anonymous'

    # if it is a agent session, use the realname if the agent for close message
    if session && session['id'] && chat_session.user_id
      agent_user = chat_session.agent_user
      if agent_user[:name]
        realname = agent_user[:name]
      end
    end

    # notify participants
    message = {
      event: 'chat_session_left',
      data:  {
        realname:   realname,
        session_id: chat_session.session_id,
      },
    }
    chat_session.send_to_recipients(message, client_id)

    Chat.broadcast_agent_state_update([chat_session.chat_id])
  end
end
