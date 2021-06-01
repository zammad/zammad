# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Escalation
  attr_reader :ticket

  def initialize(ticket, force: false)
    @ticket = ticket
    @force  = force
  end

  def preferences
    @preferences ||= Escalation::TicketPreferences.new(ticket)
  end

  def biz
    @biz ||= calendar&.biz breaks: biz_breaks
  end

  def biz_breaks
    @biz_breaks ||= Escalation::TicketBizBreak.new(ticket, calendar).biz_breaks
  end

  def escalation_disabled?
    @escalation_disabled ||= Ticket::State.lookup(id: ticket.state_id).ignore_escalation?
  end

  def sla
    @sla ||= Sla.for_ticket(ticket)
  end

  def calendar
    @calendar ||= sla&.calendar
  end

  def forced?
    !!@force
  end

  def force!
    @force = true
  end

  def calculatable?
    !escalation_disabled? || preferences.close_at_changed?(ticket) || preferences.last_contact_at_changed?(ticket)
  end

  def calculate!
    calculate

    ticket.save! if ticket.has_changes_to_save?
  end

  def calculate
    if !calculatable? && !forced?
      calculate_not_calculatable
    elsif !calendar
      calculate_no_calendar
    elsif forced? || any_changes?
      enforce_if_needed
      update_escalations
      update_statistics
      apply_preferences
    end
  end

  def any_changes?
    preferences.any_changes?(ticket, sla, escalation_disabled?)
  end

  def assign_reset
    ticket.assign_attributes(
      escalation_at:                nil,
      first_response_escalation_at: nil,
      update_escalation_at:         nil,
      close_escalation_at:          nil
    )
  end

  def calculate_not_calculatable
    assign_reset

    apply_preferences if !preferences.hash[:escalation_disabled]
  end

  def calculate_no_calendar
    assign_reset
  end

  def apply_preferences
    preferences.update_preferences(ticket, sla, escalation_disabled?)
  end

  def enforce_if_needed
    return if !preferences.sla_changed?(sla) && !preferences.calendar_changed?(sla.calendar)

    force!
  end

  def update_escalations
    ticket.assign_attributes [escalation_first_response, escalation_update, escalation_close]
      .compact
      .each_with_object({}) { |elem, memo| memo.merge!(elem) }

    ticket.escalation_at = calculate_next_escalation
  end

  def update_statistics
    ticket.assign_attributes [statistics_first_response, statistics_update, statistics_close]
      .compact
      .each_with_object({}) { |elem, memo| memo.merge!(elem) }
  end

  private

  # escalation

  # skip escalation neither forced
  # nor state switched from closed to open
  def skip_escalation?
    !forced? && !preferences.escalation_became_enabled?(escalation_disabled?)
  end

  def escalation_first_response
    return if skip_escalation? && !preferences.first_response_at_changed?(ticket)

    nullify = escalation_disabled? || ticket.first_response_at.present?

    {
      first_response_escalation_at: nullify ? nil : calculate_time(ticket.created_at, sla.first_response_time)
    }
  end

  def escalation_update
    return if skip_escalation? && !preferences.last_update_at_changed?(ticket)

    nullify   = escalation_disabled? || ticket.agent_responded?
    timestamp = nullify ? nil : ticket.last_contact_customer_at

    {
      update_escalation_at: timestamp ? calculate_time(timestamp, sla.update_time) : nil
    }
  end

  def escalation_close
    return if skip_escalation? && !preferences.close_at_changed?(ticket)

    nullify = escalation_disabled? || ticket.close_at.present?

    {
      close_escalation_at: nullify ? nil : calculate_time(ticket.created_at, sla.solution_time)
    }
  end

  def calculate_time(start_time, span)
    return if span.nil? || !span.positive?

    Escalation::DestinationTime.new(start_time, span, biz).destination_time
  end

  def calculate_next_escalation
    return if escalation_disabled?

    [
      (ticket.first_response_escalation_at if !ticket.first_response_at),
      ticket.update_escalation_at,
      (ticket.close_escalation_at if !ticket.close_at)
    ].compact.min
  end

  # statistics

  def skip_statistics_first_response?
    return true if !forced? && !preferences.first_response_at_changed?(ticket)

    ticket.first_response_at.blank? || sla.first_response_time.blank?
  end

  def statistics_first_response
    return if skip_statistics_first_response?

    minutes = calculate_minutes(ticket.created_at, ticket.first_response_at)

    {
      first_response_in_min:      minutes,
      first_response_diff_in_min: minutes ? (sla.first_response_time - minutes) : nil
    }
  end

  def skip_statistics_update?
    return true if !forced? && !preferences.last_update_at_changed?(ticket)
    return true if !sla.update_time

    !ticket.agent_responded?
  end

  # ATTENTION: Recalculation after SLA change won't happen
  # SLA change will cause wrong statistics in some edge cases.
  # Since this changes `update_in_min` calculation to retain longest timespan.
  # But it does not keep track of previous update times.
  def statistics_update_applicable?(minutes)
    ticket.update_in_min.blank? || minutes > ticket.update_in_min # keep longest timespan
  end

  def statistics_update
    return if skip_statistics_update?

    minutes = calculate_minutes(ticket.last_contact_customer_at, ticket.last_contact_agent_at)

    return if !forced? && !statistics_update_applicable?(minutes)

    {
      update_in_min:      minutes,
      update_diff_in_min: minutes ? (sla.update_time - minutes) : nil
    }
  end

  def skip_statistics_close?
    return true if !forced? && !preferences.close_at_changed?(ticket)

    ticket.close_at.blank? || sla.solution_time.blank?
  end

  def statistics_close
    return if skip_statistics_close?

    minutes = calculate_minutes(ticket.created_at, ticket.close_at)

    {
      close_in_min:      minutes,
      close_diff_in_min: minutes ? (sla.solution_time - minutes) : nil
    }
  end

  def calculate_minutes(start_time, end_time)
    return if !end_time || !start_time

    Escalation::PeriodWorkingMinutes.new(start_time, end_time, ticket, biz).period_working_minutes
  end
end
