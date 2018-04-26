# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Observer::Session < ActiveRecord::Observer
  observe 'active_record::_session_store::_session'

  def before_create(record)
    check(record)
  end

  def before_update(record)
    check(record)
  end

  # move the persistent attribute from the sub structure
  # to the first level so it gets stored in the database
  # column to make the cleanup lookup more performant
  def check(record)
    return if !record.data
    return if record[:persistent]

    return if !record.data['persistent']

    record[:persistent] = record.data['persistent']
    record.data.delete('persistent')
  end

end
