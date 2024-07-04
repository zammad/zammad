# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftStart < ApplicationModel
  include HasDefaultModelUserRelations

  include CanCloneAttachments
  include ChecksClientNotification

  belongs_to :group

  validates :name, presence: true

  before_validation :clear_group_id
  after_commit :trigger_subscriptions

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

  private

  def clear_group_id
    content.delete :group_id
  end

  def trigger_subscriptions
    [group_id, group_id_previously_was]
      .compact
      .uniq
      .each do |elem|
        Gql::Subscriptions::Ticket::SharedDraft::Start::UpdateByGroup
          .trigger(nil, arguments: { group_id: Gql::ZammadSchema.id_from_internal_id('Group', elem) })
      end
  end
end
