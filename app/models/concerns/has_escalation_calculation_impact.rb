# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasEscalationCalculationImpact
  extend ActiveSupport::Concern

  included do
    after_commit :enqueue_ticket_escalation_rebuild_job
  end

  private

  def enqueue_ticket_escalation_rebuild_job

    # return if we run import mode
    return if Setting.get('import_mode') && !Setting.get('import_ignore_sla')

    # check if condition has changed
    fields_to_check = if instance_of?(Sla)
                        %w[condition calendar_id first_response_time update_time solution_time]
                      else
                        %w[timezone business_hours default ical_url public_holidays]
                      end

    return if fields_to_check.none? do |item|
      next if !saved_change_to_attribute(item)

      saved_change_to_attribute(item)[0] != saved_change_to_attribute(item)[1]
    end

    TicketEscalationRebuildJob.perform_later
  end
end
