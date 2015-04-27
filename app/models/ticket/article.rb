# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
# rubocop:disable ClassAndModuleChildren
class Ticket::Article < ApplicationModel
  load 'ticket/article/assets.rb'
  include Ticket::Article::Assets
  load 'ticket/article/history_log.rb'
  include Ticket::Article::HistoryLog
  load 'ticket/article/activity_stream_log.rb'
  include Ticket::Article::ActivityStreamLog

  belongs_to    :ticket
  belongs_to    :type,        class_name: 'Ticket::Article::Type'
  belongs_to    :sender,      class_name: 'Ticket::Article::Sender'
  belongs_to    :created_by,  class_name: 'User'
  belongs_to    :updated_by,  class_name: 'User'
  before_create :check_subject
  before_update :check_subject
  notify_clients_support

  activity_stream_support ignore_attributes: {
    type_id: true,
    sender_id: true,
  }

  history_support ignore_attributes: {
    type_id: true,
    sender_id: true,
  }

  private

  def check_subject
    if self.subject
      self.subject.gsub!(/\s|\t|\r/, ' ')
    end
  end

  class Flag < ApplicationModel
  end

  class Sender < ApplicationModel
    validates   :name, presence: true
    latest_change_support
  end

  class Type < ApplicationModel
    validates   :name, presence: true
    latest_change_support
  end
end
