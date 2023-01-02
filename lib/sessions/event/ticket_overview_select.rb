# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::TicketOverviewSelect < Sessions::Event::Base

=begin

Observing every ticket overview of each agent session does not scale well on larger systems (e.g. 60 ticket overviews per agent).
With this change, only the five most recently used ones are checked on every iteration.
A full check is still performed (every 60 seconds). This reduces the overall load.

  App.WebSocket.send({event:'ticket_overview_select'}, data: { view: ''})

=end

  def run
    return if @payload['data'].blank?
    return if @payload['data']['view'].blank?
    return if @session['id'].blank?

    Sessions::Backend::TicketOverviewList.overview_history_append(@payload['data']['view'], @session['id'])

    nil
  end

end
