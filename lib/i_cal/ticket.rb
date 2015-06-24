# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module ICal::Ticket

  def self.preferenced(user)

    events_data = []
    return events_data if !user.preferences[:ical]
    return events_data if !user.preferences[:ical][:ticket]

    preferences = user.preferences[:ical][:ticket]

    [:new_open, :pending, :escalation].each { |state_type|

      next if !preferences[ state_type ]

      owner_ids = []
      if preferences[ state_type ][:own]
        owner_ids = [ user.id ]
      end
      if preferences[ state_type ][:not_assigned]
        owner_ids.push( 1 )
      end

      next if owner_ids.empty?

      if state_type == :new_open
        events_data += new_open(user, owner_ids)
      elsif state_type == :pending
        events_data += pending(user, owner_ids)
      elsif state_type == :escalation
        events_data += escalation(user, owner_ids)
      end
    }

    events_data
  end

  private

  def self.new_open(user, owner_ids)

    events_data = []
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

  def self.pending(user, owner_ids)

    events_data = []
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
      current_user: user,
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

  def self.escalation(user, owner_ids)

    events_data = []
    return events_data if owner_ids.empty?

    condition = [
      'tickets.owner_id IN (?) AND tickets.escalation_time IS NOT NULL', owner_ids
    ]

    tickets = Ticket.search(
      current_user: user,
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
