# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::CoreWorkflow < Sessions::Event::Base
  database_connection_required

  def run
    {
      event: 'core_workflow',
      data:  CoreWorkflow.perform(payload: @payload, user: current_user)
    }
  end

end
