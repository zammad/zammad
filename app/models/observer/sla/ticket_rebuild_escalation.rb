# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Sla::TicketRebuildEscalation < ActiveRecord::Observer
  observe 'sla', 'calendar'

  def after_commit(record)
    return if _check(record)

    _rebuild
  end

  private

  def _rebuild
    Cache.delete('SLA::List::Active')

    # send background job
    SlaTicketRebuildEscalationJob.perform_later
  end

  def _check(record)

    # return if we run import mode
    return true if Setting.get('import_mode') && !Setting.get('import_ignore_sla')

    # check if condition has changed
    changed = false
    fields_to_check = if record.class == Sla
                        %w[condition calendar_id first_response_time update_time solution_time]
                      else
                        %w[timezone business_hours default ical_url public_holidays]
                      end
    fields_to_check.each do |item|
      next if !record.saved_change_to_attribute(item)
      next if record.saved_change_to_attribute(item)[0] == record.saved_change_to_attribute(item)[1]

      changed = true
    end
    return true if !changed

    false
  end

end
