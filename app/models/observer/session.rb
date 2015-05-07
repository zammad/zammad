# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'history'

class Observer::Session < ActiveRecord::Observer
  observe 'active_record::_session_store::_session'

  def before_create(record)
    check(record)
  end

  def before_update(record)
    check(record)
  end

  def check(record)
    return if !record.data
    return if record[:request_type]

    # remember request type
    return if !record.data['request_type']

    record[:request_type] = record.data['request_type']
    record.data.delete('request_type')
  end

end
