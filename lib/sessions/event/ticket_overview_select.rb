# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::TicketOverviewSelect < Sessions::Event::Base

=begin

Event module to serve spool messages and send them to new client connection.

To execute this manually, just paste the following into the browser console

  App.WebSocket.send({event:'spool'})

=end

  def run
    return if @payload['data'].blank?
    return if @payload['data']['view'].blank?
    return if @session['id'].blank?

    Sessions::Backend::TicketOverviewList.overview_history_append(@payload['data']['view'], @session['id'])

    nil
  end

end
