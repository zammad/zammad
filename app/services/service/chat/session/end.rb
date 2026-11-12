# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What the legacy chat_session_close event effectively does. Its participant count reads a misspelled key
#   nothing writes, so it always closes the session and never takes the branch of leaving it.
class Service::Chat::Session::End < Service::Base
  requires_current_user!

  attr_reader :session

  def initialize(session:)
    @session = session
  end

  def execute
    # The check holds only under the lock: another agent can take the session after a transfer between its load and the write.
    session.with_lock do
      raise Exceptions::Forbidden, __('You are not running this chat session.') if !session.running_for?(current_user)

      session.update!(state: 'closed')
    end

    ::Chat.broadcast_agent_state_update([session.chat_id], agent_ids: [session.user_id])
    ::Chat.broadcast_customer_state_update(session.chat_id)

    session.send_to_recipients(
      event: 'chat_session_closed',
      data:  {
        session_id: session.session_id,
        realname:   session.agent_user&.dig(:name) || 'Anonymous',
      },
    )

    session
  end
end
