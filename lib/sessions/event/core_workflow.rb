# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::CoreWorkflow < Sessions::Event::Base
  database_connection_required

  def run
    {
      event: 'core_workflow',
      data:  CoreWorkflow.perform(payload: @payload, user: current_user)
    }
  end

end
