# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::CloseTime < ActiveRecord::Observer
  observe 'ticket'

  def before_create(record)
    _check(record)
  end

  def before_update(record)
    _check(record)
  end

  private

  def _check(record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    # check if close_at is already set
    return true if record.close_at

    # check if ticket is closed now
    return true if !record.state_id

    state = Ticket::State.lookup(id: record.state_id)
    state_type = Ticket::StateType.lookup(id: state.state_type_id)
    return true if state_type.name != 'closed'

    # set close_at
    record.close_at = Time.zone.now
  end
end
