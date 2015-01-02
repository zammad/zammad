# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Ticket::Article < ApplicationModel
  load 'ticket/article/assets.rb'
  include Ticket::Article::Assets
  load 'ticket/article/history_log.rb'
  include Ticket::Article::HistoryLog
  load 'ticket/article/activity_stream_log.rb'
  include Ticket::Article::ActivityStreamLog

  belongs_to    :ticket
  belongs_to    :type,        :class_name => 'Ticket::Article::Type'
  belongs_to    :sender,      :class_name => 'Ticket::Article::Sender'
  belongs_to    :created_by,  :class_name => 'User'
  belongs_to    :updated_by,  :class_name => 'User'
  after_create  :notify_clients_after_create
  after_update  :notify_clients_after_update
  after_destroy :notify_clients_after_destroy

  activity_stream_support :ignore_attributes => {
    :type_id   => true,
    :sender_id => true,
  }

  history_support :ignore_attributes => {
    :type_id   => true,
    :sender_id => true,
  }

  class Flag < ApplicationModel
  end

  class Sender < ApplicationModel
    validates   :name, :presence => true
  end

  class Type < ApplicationModel
    validates   :name, :presence => true
  end
end
