# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftStart < ApplicationModel
  include CanCloneAttachments
  include ChecksClientNotification

  belongs_to :group
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

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
