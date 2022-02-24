# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftZoom < ApplicationModel
  include CanCloneAttachments
  include ChecksClientNotification

  belongs_to :ticket, touch: true

  store :new_article
  store :ticket_attributes

  # required by CanCloneAttachments
  def content_type
    'text/html'
  end
end
