class Sessions::Event::TicketOverviewIndex < Sessions::Event::Base
  database_connection_required

  def run
    return if !valid_session?

    Sessions::Backend::TicketOverviewList.reset(@session['id'])
  end

end
