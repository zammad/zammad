# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftStart < ApplicationModel
  include HasDefaultModelUserRelations

  include CanCloneAttachments
  include ChecksClientNotification

  belongs_to :group

  validates :name, presence: true

  store :content

  # don't include content into assets which may be huge
  # assets are used to load the whole list of available drafts
  # content is loaded separately
  def filter_attributes(attributes)
    super.except! 'content'
  end

  # required by CanCloneAttachments
  def content_type
    'text/html'
  end
end
