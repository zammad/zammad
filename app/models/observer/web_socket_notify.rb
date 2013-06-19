# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'session'

class Observer::WebSocketNotify < ActiveRecord::Observer
  observe :ticket, :user, 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    Session.broadcast(
      :event => record.class.name.downcase + ':created',
      :data => { :id => record.id, :updated_at => record.updated_at }
    )
  end

  def after_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')
    puts "#{record.class.name.downcase} UPDATED " + record.updated_at.to_s
    Session.broadcast(
      :event => record.class.name.downcase + ':updated',
      :data => { :id => record.id, :updated_at => record.updated_at }
    )
  end
end
