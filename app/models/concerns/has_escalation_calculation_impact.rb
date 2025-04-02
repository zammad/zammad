# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module HasEscalationCalculationImpact
  extend ActiveSupport::Concern

  included do
    after_commit :enqueue_ticket_escalation_rebuild_job
  end

  private

  def enqueue_ticket_escalation_rebuild_job

    # return if we run import mode
    return if Setting.get('import_mode') && !Setting.get('import_ignore_sla')
    return if !needs_rebuilding?

    TicketEscalationRebuildJob.perform_later
  end

  def needs_rebuilding?
    case self
    when Sla
      return true if destroyed?

      %w[condition calendar_id first_response_time update_time solution_time].any? do |item|
        saved_change_to_attribute?(item)
      end
    when Calendar
      %w[timezone business_hours default ical_url public_holidays].any? do |item|
        saved_change_to_attribute?(item)
      end
    end
  end
end
