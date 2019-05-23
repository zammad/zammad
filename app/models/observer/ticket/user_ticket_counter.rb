# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::UserTicketCounter < ActiveRecord::Observer
  observe 'ticket'

  def after_commit(record)
    user_ticket_counter_update(record)
  end

  def user_ticket_counter_update(record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    return true if BulkImportInfo.enabled?

    return true if record.destroyed?

    return true if !record.customer_id

    # send background job
    TicketUserTicketCounterJob.perform_later(
      record.customer_id,
      UserInfo.current_user_id || record.updated_by_id,
    )
  end

end
