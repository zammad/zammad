class Observer::Ticket::CloseTime < ActiveRecord::Observer
  observe 'ticket'

  def after_update(record)
#    puts 'check close time'

    # return if we run import mode
    return if Setting.get('import_mode')

    # check if close_time is already set
    return true if record.close_time

    # check if ticket is closed now
    ticket_state = Ticket::State.find( record.ticket_state_id )
    ticket_state_type = Ticket::StateType.find( ticket_state.ticket_state_type_id )
    return true if ticket_state_type.name != 'closed'

    # set close_time
    record.close_time = Time.now

    # save ticket
    record.save
  end
end  