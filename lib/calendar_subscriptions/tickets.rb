# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CalendarSubscriptions::Tickets
  ALLOWED_METHODS = %w[all new_open pending escalation].freeze

  def initialize(user, preferences, time_zone)
    @user         = user
    @preferences  = preferences
    @time_zone    = time_zone
    @translations = {}
  end

  def all
    return [] if @preferences.blank?

    new_open + pending + escalation
  end

  def alarm?
    !!@preferences[:alarm]
  end

  def owner_ids(method)
    output = []

    output << @user.id if @preferences.dig(method, :own)
    output << 1        if @preferences.dig(method, :not_assigned)

    output
  end

  def new_open
    owner_ids = owner_ids(:new_open)
    return [] if owner_ids.blank?

    fetch_tickets(owner_ids, state_names: %w[new open]).filter_map do |ticket|
      event_data_with_date(
        summary: base_summary(ticket),
        date:    Time.zone.today,
        type:    'new_open',
        ticket:  ticket,
      )
    end
  end

  def pending
    owner_ids = owner_ids(:pending)
    return [] if owner_ids.blank?

    fetch_tickets(owner_ids, state_names: ['pending reminder', 'pending action']).filter_map do |ticket|
      next if !ticket.pending_time

      pending_time = [ticket.pending_time, Time.zone.today].max

      event_data_with_time(
        summary: pending_summary(ticket),
        time:    pending_time,
        type:    'pending',
        ticket:  ticket
      )
    end
  end

  def escalation
    owner_ids = owner_ids(:escalation)
    return [] if owner_ids.blank?

    fetch_tickets(owner_ids, escalation_check: true).filter_map do |ticket|
      next if !ticket.escalation_at

      escalation_at = [ticket.escalation_at, Time.zone.today].max

      event_data_with_time(
        summary: escalated_summary(ticket),
        time:    escalation_at,
        type:    'escalated',
        ticket:  ticket
      )
    end
  end

  private

  def generate_conditions(owner_ids, state_names: nil, escalation_check: false)
    output = {
      'ticket.owner_id' => {
        operator: 'is',
        value:    owner_ids,
      },
    }

    if state_names
      output['ticket.state_id'] = {
        operator: 'is',
        value:    Ticket::State.where(
          state_type_id: Ticket::StateType.where(
            name: state_names,
          ),
        ).map(&:id),
      }
    end

    if escalation_check
      output['ticket.escalation_at'] = {
        operator: 'is not',
        value:    nil,
      }
    end

    output
  end

  def fetch_tickets(...)
    condition = generate_conditions(...)

    Ticket.search(
      current_user: @user,
      condition:    condition,
    )
  end

  def translate_to_user(input)
    return @translations[input] if @translations[input]

    @translations[input] = Translation.translate(@user.locale, input)
  end

  def base_event_data(summary:, timestamp:, type:, ticket:)
    {
      dtstart:     timestamp,
      dtend:       timestamp,
      summary:     summary,
      description: "T##{ticket.number}",
      type:        type
    }
  end

  def event_data_with_date(date:, summary:, type:, ticket:)
    timestamp = Icalendar::Values::Date.new(date, 'tzid' => @time_zone)

    base_event_data(
      summary:,
      type:,
      ticket:,
      timestamp:,
    )
  end

  def event_data_with_time(time:, summary:, type:, ticket:)
    timestamp = Icalendar::Values::DateTime.new(time, 'tzid' => @time_zone)

    output = base_event_data(
      summary:,
      type:,
      ticket:,
      timestamp:,
    )

    if alarm?
      output[:alarm] = {
        summary: summary,
        trigger: '-PT1M',
      }
    end

    output
  end

  def base_summary(ticket)
    translated_state = translate_to_user(ticket.state.name)
    translated_ticket = translate_to_user('ticket')

    "#{translated_state} #{translated_ticket}: '#{ticket.title}'"
  end

  def pending_summary(ticket)
    translated_customer = translate_to_user('customer')

    "#{base_summary(ticket)} #{translated_customer}: #{ticket.customer.longname}"
  end

  def escalated_summary(ticket)
    translated_ticket_escalation = translate_to_user('ticket escalation')
    translated_customer          = translate_to_user('customer')

    "#{translated_ticket_escalation}: '#{ticket.title}' #{translated_customer}: #{ticket.customer.longname}"
  end
end
