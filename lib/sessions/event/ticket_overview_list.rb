# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::TicketOverviewList < Sessions::Event::Base
  database_connection_required

  def run
    return if !valid_session?

    Sessions::Backend::TicketOverviewList.reset(@session['id'])
  end

end
