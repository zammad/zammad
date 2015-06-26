# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class CalendarSubscriptions::Tickets

  def initialize(user, preferences)
    @user        = user
    @preferences = preferences
  end

  def all

    events_data = []
    return events_data if @preferences.empty?

    events_data += new_open
    events_data += pending
    events_data += escalation

    events_data
  end

  def owner_ids(method)

    owner_ids = []

    return owner_ids if @preferences.empty?
    return owner_ids if !@preferences[ method ]
    return owner_ids if @preferences[ method ].empty?

    preferences = @preferences[ method ]

    if preferences[:own]
      owner_ids = [ @user.id ]
    end
    if preferences[:not_assigned]
      owner_ids.push( 1 )
    end

    owner_ids
  end

  def new_open

    events_data = []
    owner_ids   = owner_ids(:new_open)
    return events_data if owner_ids.empty?

    condition = {
      'tickets.owner_id' => owner_ids,
      'tickets.state_id' => Ticket::State.where(
        state_type_id: Ticket::StateType.where(
          name: %w(new open),
        ),
      ),
    }

    tickets = Ticket.search(
      current_user: @user,
      condition: condition,
    )

    events_data = []
    tickets.each do |ticket|

      event_data = {}

      event_data[:dtstart]     = Icalendar::Values::Date.new( Time.zone.today )
      event_data[:dtend]       = Icalendar::Values::Date.new( Time.zone.today )
      event_data[:summary]     = "#{ticket.state.name} ticket: '#{ticket.title}'"
      event_data[:description] = "T##{ticket.number}"

      events_data.push event_data
    end

    events_data
  end

  def pending

    events_data = []
    owner_ids   = owner_ids(:pending)
    return events_data if owner_ids.empty?

    condition = {
      'tickets.owner_id' => owner_ids,
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
      current_user: @user,
      condition: condition,
    )

    events_data = []
    tickets.each do |ticket|

      next if !ticket.pending_time

      event_data = {}

      pending_time = ticket.pending_time
      if pending_time < Time.zone.today
        pending_time = Time.zone.today
      end

      # rubocop:disable Rails/TimeZone
      event_data[:dtstart]     = Icalendar::Values::DateTime.new( pending_time )
      event_data[:dtend]       = Icalendar::Values::DateTime.new( pending_time )
      # rubocop:enable Rails/TimeZone
      event_data[:summary]     = "#{ticket.state.name} ticket: '#{ticket.title}'"
      event_data[:description] = "T##{ticket.number}"

      events_data.push event_data
    end

    events_data
  end

  def escalation

    events_data = []
    owner_ids   = owner_ids(:escalation)
    return events_data if owner_ids.empty?

    condition = [
      'tickets.owner_id IN (?) AND tickets.escalation_time IS NOT NULL', owner_ids
    ]

    tickets = Ticket.search(
      current_user: @user,
      condition: condition,
    )

    tickets.each do |ticket|

      next if !ticket.escalation_time

      event_data = {}

      escalation_time = ticket.escalation_time
      if escalation_time < Time.zone.today
        escalation_time = Time.zone.today
      end

      # rubocop:disable Rails/TimeZone
      event_data[:dtstart]     = Icalendar::Values::DateTime.new( escalation_time )
      event_data[:dtend]       = Icalendar::Values::DateTime.new( escalation_time )
      # rubocop:enable Rails/TimeZone
      event_data[:summary]     = "ticket escalation: '#{ticket.title}'"
      event_data[:description] = "T##{ticket.number}"

      events_data.push event_data
    end

    events_data
  end
end
