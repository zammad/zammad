# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::StatsReopen < ActiveRecord::Observer
  load 'stats/ticket_reopen.rb'

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
    Stats::TicketReopen.log('Ticket', record.id, record.changes, record.updated_by_id)
  end
end
