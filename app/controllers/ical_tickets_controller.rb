# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

require 'icalendar'

class IcalTicketsController < ApplicationController
  before_action { authentication_check( { basic_auth_promt: true, token_action: 'iCal' } ) }

  # @path       [GET] /ical/tickets
  #
  # @summary          Returns an iCal file with all tickets (open, new, pending, esclation) as events.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def all
    new_open_events_data   = ICal::Ticket.new_open(current_user)
    pending_events_data    = ICal::Ticket.pending(current_user)
    escalation_events_data = ICal::Ticket.escalation(current_user)

    events_data = new_open_events_data + pending_events_data + escalation_events_data

    ical = ICal.to_ical( events_data )

    send_data(
      ical,
      filename: 'zammad_tickets.ical',
      type: 'text/plain',
      disposition: 'inline'
    )
  end

  # @path       [GET] /ical/tickets_new_open
  #
  # @summary          Returns an iCal file with all new and open tickets as events.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def new_open
    events_data = ICal::Ticket.new_open(current_user)

    ical = ICal.to_ical( events_data )

    send_data(
      ical,
      filename: 'zammad_tickets_new_open.ical',
      type: 'text/plain',
      disposition: 'inline'
    )
  end

  # @path       [GET] /ical/tickets_pending
  #
  # @summary          Returns an iCal file with all pending tickets as events.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def pending
    events_data = ICal::Ticket.pending(current_user)

    ical = ICal.to_ical( events_data )

    send_data(
      ical,
      filename: 'zammad_tickets_pending.ical',
      type: 'text/plain',
      disposition: 'inline'
    )
  end

  # @path       [GET] /ical/ticket_escalation
  #
  # @summary          Returns an iCal file with all escalation times for tickets as events.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def escalation
    events_data = ICal::Ticket.escalation(current_user)

    ical = ICal.to_ical( events_data )

    send_data(
      ical,
      filename: 'zammad_tickets_escalation.ical',
      type: 'text/plain',
      disposition: 'inline'
    )
  end

end
