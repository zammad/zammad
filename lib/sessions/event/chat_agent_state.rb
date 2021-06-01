# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::ChatAgentState < Sessions::Event::ChatBase

=begin

a agent triggers its own chat availability state

payload

  {
    event: 'chat_agent_state',
    data: {
      active: true, # true|false
    },
  }

return is sent as message back to peer

=end

  def run
    return super if super

    # check if user has permissions
    return if !permission_check('chat.agent', 'chat')

    update_state

    {
      event: 'chat_agent_state',
      data:  {
        state:  'ok',
        active: @payload['data']['active'],
      },
    }
  end

  private

  def update_state
    chat_user = User.lookup(id: @session['id'])

    return if !Chat::Agent.state(@session['id'], @payload['data']['active'])

    chat_ids = Chat.agent_active_chat_ids(chat_user)

    # broadcast new state to agents
    Chat.broadcast_agent_state_update(chat_ids, @session['id'])
  end

end
