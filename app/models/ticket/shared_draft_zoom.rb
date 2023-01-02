# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftZoom < ApplicationModel
  include CanCloneAttachments
  include ChecksClientNotification
  include HasHistory

  belongs_to :ticket, touch: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  store :new_article
  store :ticket_attributes

  history_attributes_ignored :new_article,
                             :ticket_attributes

  # required by CanCloneAttachments
  def content_type
    'text/html'
  end

  def history_log_attributes
    {
      related_o_id:           self['ticket_id'],
      related_history_object: 'Ticket',
    }
  end

  def history_destroy
    history_log('removed', created_by_id)
  end
end
