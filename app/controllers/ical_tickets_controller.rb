# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

require 'icalendar'

class IcalTicketsController < ApplicationController
  before_action { authentication_check( { basic_auth_promt: true, token_action: 'iCal' } ) }

  # @path       [GET] /ical/tickets/:action_token
  #
  # @summary          Returns an iCal file with all tickets (open, new, pending, esclation) as events.
  #
  # @parameter        action_token(required) [String] The action_token identifying the requested User privileged for 'iCal' action.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def all

    new_open_events_data   = new_open_events_data_get
    pending_events_data    = pending_events_data_get
    escalation_events_data = escalation_events_data_get

    events_data = new_open_events_data + pending_events_data + escalation_events_data

    events_data_to_ical( events_data )
  end

  # @path       [GET] /ical/tickets_new_open/:action_token
  #
  # @summary          Returns an iCal file with all new and open tickets as events.
  #
  # @parameter        action_token(required) [String] The action_token identifying the requested User privileged for 'iCal' action.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def new_open

    events_data = new_open_events_data_get

    events_data_to_ical( events_data )
  end

  # @path       [GET] /ical/tickets_pending/:action_token
  #
  # @summary          Returns an iCal file with all pending tickets as events.
  #
  # @parameter        action_token(required) [String] The action_token identifying the requested User privileged for 'iCal' action.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def pending
    events_data = pending_events_data_get

    events_data_to_ical( events_data )
  end

  # @path       [GET] /ical/ticket_escalation/:action_token
  #
  # @summary          Returns an iCal file with all escalation times for tickets as events.
  #
  # @parameter        action_token(required) [String] The action_token identifying the requested User privileged for 'iCal' action.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def escalation
    events_data = escalation_events_data_get

    events_data_to_ical( events_data )
  end

  private

  def new_open_events_data_get

    condition = {
      'tickets.owner_id' => current_user.id,
      'tickets.state_id' => Ticket::State.where(
        state_type_id: Ticket::StateType.where(
          name: %w(new open),
        ),
      ),
    }

    tickets = Ticket.search(
      current_user: current_user,
      condition: condition,
    )

    events_data = []
    tickets.each do |ticket|

      event_data = {}

      event_data[:dtstart]     = Icalendar::Values::Date.new( Time.zone.today )
      event_data[:dtend]       = Icalendar::Values::Date.new( Time.zone.today )
      event_data[:summary]     = "#{ ticket.state.name } ticket: '#{ ticket.title }'"
      event_data[:description] = "T##{ ticket.number }"

      events_data.push event_data
    end

    events_data
  end

  def pending_events_data_get

    condition = {
      'tickets.owner_id' => current_user.id,
      'tickets.state_id' => Ticket::State.where(
        state_type_id: Ticket::StateType.where(
          name: [
            'pending reminder',
            'pending action',
          ],
        ),
      ),
    }

    tickets = Ticket.search(
      current_user: current_user,
      condition: condition,
    )

    events_data = []
    tickets.each do |ticket|

      event_data = {}

      # rubocop:disable Rails/TimeZone
      event_data[:dtstart]     = Icalendar::Values::DateTime.new( ticket.pending_time )
      event_data[:dtend]       = Icalendar::Values::DateTime.new( ticket.pending_time )
      # rubocop:enable Rails/TimeZone
      event_data[:summary]     = "#{ ticket.state.name } ticket: '#{ ticket.title }'"
      event_data[:description] = "T##{ ticket.number }"

      events_data.push event_data
    end

    events_data
  end

  def escalation_events_data_get

    condition = [
      'tickets.escalation_time IS NOT NULL',
      'tickets.owner_id = ?', current_user.id
    ]

    tickets = Ticket.search(
      current_user: current_user,
      condition: condition,
    )

    events_data = []
    tickets.each do |ticket|

      event_data = {}

      # rubocop:disable Rails/TimeZone
      event_data[:dtstart]     = Icalendar::Values::DateTime.new( ticket.escalation_time )
      event_data[:dtend]       = Icalendar::Values::DateTime.new( ticket.escalation_time )
      # rubocop:enable Rails/TimeZone
      event_data[:summary]     = "ticket escalation: '#{ ticket.title }'"
      event_data[:description] = "T##{ ticket.number }"

      events_data.push event_data
    end

    events_data
  end

  def events_data_to_ical(events_data)

    cal = Icalendar::Calendar.new

    events_data.each do |event_data|

      cal.event do |e|
        e.dtstart     = event_data[:dtstart]
        e.dtend       = event_data[:dtend]
        e.summary     = event_data[:summary]
        e.description = event_data[:description]
        e.ip_class    = 'PRIVATE'
      end

    end

    send_data(
      cal.to_ical,
      filename: 'zammad.ical',
      type: 'text/plain',
      disposition: 'inline'
    )
  end

end
