# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Escalation
  class TicketPreferences
    KEYS = %i[escalation_disabled
              first_response_at last_update_at close_at escalation_at
              sla_id sla_updated_at
              calendar_id calendar_updated_at last_contact_at].freeze

    attr_reader :hash

    def initialize(ticket)
      @hash = {}

      KEYS.each do |key|
        @hash[key] = ticket.preferences.dig(:escalation_calculation, key) || nil
      end
    end

    def escalation_became_enabled?(escalation_disabled)
      !escalation_disabled && @hash[:escalation_disabled] != escalation_disabled
    end

    def sla_changed?(sla)
      @hash[:sla_id] != sla&.id || @hash[:sla_updated_at] != sla&.updated_at
    end

    def calendar_changed?(calendar)
      @hash[:calendar_id] != calendar&.id || @hash[:calendar_updated_at] != calendar&.updated_at
    end

    def first_response_at_changed?(ticket)
      @hash[:first_response_at] != ticket.first_response_at
    end

    def last_update_at_changed?(ticket)
      @hash[:last_update_at] != ticket.last_original_update_at || ticket.saved_change_to_state_id?
    end

    def close_at_changed?(ticket)
      @hash[:close_at] != ticket.close_at
    end

    def last_contact_at_changed?(ticket)
      @hash[:last_contact_at] != ticket.last_contact_at
    end

    def property_changes?(ticket)
      %i[first_response_at last_update_at close_at].any? { |elem| send("#{elem}_changed?", ticket) }
    end

    def any_changes?(ticket, sla, escalation_disabled)
      property_changes?(ticket) || sla_changed?(sla) || calendar_changed?(sla&.calendar) || @hash[:escalation_disabled] != escalation_disabled
    end

    def update_preferences(ticket, sla, escalation_disabled)
      new_hash = hash_of(ticket, sla, escalation_disabled)

      return if new_hash == { escalation_disabled: false } && !@hash[:escalation_disabled] # do not update when update not necessary

      ticket.preferences[:escalation_calculation] = new_hash
    end

    def hash_of(ticket, sla, escalation_disabled)
      {
        first_response_at:   ticket.first_response_at,
        last_update_at:      ticket.last_original_update_at,
        close_at:            ticket.close_at,
        last_contact_at:     ticket.last_contact_at,
        sla_id:              sla&.id,
        sla_updated_at:      sla&.updated_at,
        calendar_id:         sla&.calendar&.id,
        calendar_updated_at: sla&.calendar&.updated_at,
        escalation_disabled: escalation_disabled,
      }.compact
    end
  end
end
