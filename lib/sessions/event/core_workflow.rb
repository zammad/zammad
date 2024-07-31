# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::CoreWorkflow < Sessions::Event::Base
  database_connection_required

  def run
    return if !valid_session?

    {
      event: 'core_workflow',
      data:  CoreWorkflow.perform(payload: @payload, user: current_user)
    }
  end

end
