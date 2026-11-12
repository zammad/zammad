# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Chat::Session::Rename < Service::Base
  requires_current_user!

  attr_reader :session, :name

  def initialize(session:, name:)
    @session = session
    @name    = name
  end

  # Any state of the agent's own session: a closed one keeps its window until the agent closes it.
  def execute
    raise Exceptions::Forbidden if session.user_id != current_user.id

    session.update!(name: name.strip.presence)

    session
  end
end
