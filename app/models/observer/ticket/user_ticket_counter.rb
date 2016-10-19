# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::UserTicketCounter < ActiveRecord::Observer
  observe 'ticket'

  def after_create(record)
    user_ticket_counter_update(record)
  end

  def after_update(record)
    user_ticket_counter_update(record)
  end

  def user_ticket_counter_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    return if !record.customer_id

    # send background job
    Delayed::Job.enqueue(
      Observer::Ticket::UserTicketCounter::BackgroundJob.new(
        record.customer_id,
        UserInfo.current_user_id || record.updated_by_id,
      )
    )
  end

end
