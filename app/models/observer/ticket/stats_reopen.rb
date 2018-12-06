# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'stats/ticket_reopen'

class Observer::Ticket::StatsReopen < ActiveRecord::Observer

  observe 'ticket'

  def after_create(record)
    _check(record)
  end

  def after_update(record)
    _check(record)
  end

  private

  def _check(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    Stats::TicketReopen.log('Ticket', record.id, record.saved_changes, record.updated_by_id)
  end
end
