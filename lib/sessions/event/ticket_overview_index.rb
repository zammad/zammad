# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::TicketOverviewIndex < Sessions::Event::Base
  database_connection_required

  def run
    return if !valid_session?

    Sessions::Backend::TicketOverviewList.reset(@session['id'])
  end

end
