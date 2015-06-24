# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module ICal::Ticket

  def self.new_open(user)

    condition = {
      'tickets.owner_id' => user.id,
      'tickets.state_id' => Ticket::State.where(
        state_type_id: Ticket::StateType.where(
          name: %w(new open),
        ),
      ),
    }

    tickets = Ticket.search(
      current_user: user,
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

  def self.pending(user)

    condition = {
      'tickets.owner_id' => user.id,
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
      current_user: user,
      condition: condition,
    )

    events_data = []
    tickets.each do |ticket|

      next if !ticket.pending_time

      event_data = {}

      # rubocop:disable Rails/TimeZone
      event_data[:dtstart]     = Icalendar::Values::DateTime.new( ticket.pending_time )
      event_data[:dtend]       = Icalendar::Values::DateTime.new( ticket.pending_time )
      # rubocop:enable Rails/TimeZone
      event_data[:summary]     = "#{ticket.state.name} ticket: '#{ticket.title}'"
      event_data[:description] = "T##{ticket.number}"

      events_data.push event_data
    end

    events_data
  end

  def self.escalation(user)

    condition = [
      'tickets.escalation_time IS NOT NULL',
      'tickets.owner_id = ?', user.id
    ]

    tickets = Ticket.search(
      current_user: user,
      condition: condition,
    )

    events_data = []
    tickets.each do |ticket|

      next if !ticket.escalation_time

      event_data = {}

      # rubocop:disable Rails/TimeZone
      event_data[:dtstart]     = Icalendar::Values::DateTime.new( ticket.escalation_time )
      event_data[:dtend]       = Icalendar::Values::DateTime.new( ticket.escalation_time )
      # rubocop:enable Rails/TimeZone
      event_data[:summary]     = "ticket escalation: '#{ticket.title}'"
      event_data[:description] = "T##{ticket.number}"

      events_data.push event_data
    end

    events_data
  end

end
