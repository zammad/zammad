# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Answer < ApplicationModel
  include HasTranslations
  include HasAgentAllowedParams
  include CanBePublished
  include HasKnowledgeBaseAttachmentPermissions
  include ChecksKbClientNotification
  include CanCloneAttachments

  AGENT_ALLOWED_ATTRIBUTES       = %i[category_id promoted internal_note].freeze
  AGENT_ALLOWED_NESTED_RELATIONS = %i[translations].freeze

  belongs_to :category, class_name: 'KnowledgeBase::Category', inverse_of: :answers, touch: true

  scope :include_contents, -> { eager_load(translations: :content) }
  scope :sorted,           -> { order(position: :asc) }

  acts_as_list scope: :category, top_of_list: 0

  validates :category, presence: true

  # provide consistent naming with KB category
  alias_attribute :parent, :category

  alias assets_essential assets

  def attributes_with_association_ids
    key = "#{self.class}::aws::#{id}"

    cache = Cache.read(key)
    return cache if cache

    attrs = super

    attrs[:attachments] = attachments_sorted.map { |elem| self.class.attachment_to_hash(elem) }

    Cache.write(key, attrs)

    attrs
  end

  def assets(data = {})
    return data if assets_added_to?(data)

    data = super(data)
    data = category.assets(data)

    # include all siblings to make sure ordering is always up to date. Reader gets only accessible siblings.
    siblings = category.answers

    if !User.lookup(id: UserInfo.current_user_id)&.permissions?('knowledge_base.editor')
      siblings = siblings.internal
    end

    data = ApplicationModel::CanAssets.reduce(siblings, data)
    ApplicationModel::CanAssets.reduce(translations, data)
  end

  attachments_cleanup!

  def attachments_sorted
    attachments.sort_by { |elem| elem.filename.downcase }
  end

  def add_attachment(file)
    filename     = file.try(:original_filename) || File.basename(file.path)
    content_type = file.try(:content_type) || MIME::Types.type_for(filename).first&.content_type || 'application/octet-stream'

    Store.add(
      object:      self.class.name,
      o_id:        id,
      data:        file.read,
      filename:    filename,
      preferences: { 'Content-Type': content_type }
    )

    touch # rubocop:disable Rails/SkipsModelValidations
    translations.each(&:touch)

    true
  end

  def remove_attachment(attachment_id)
    attachment = attachments.find { |elem| elem.id == attachment_id.to_i }

    raise ActiveRecord::RecordNotFound if attachment.nil?

    Store.remove_item(attachment.id)

    touch # rubocop:disable Rails/SkipsModelValidations
    translations.each(&:touch)

    true
  end

  def api_url
    Rails.application.routes.url_helpers.knowledge_base_answer_path(category.knowledge_base, self)
  end

  # required by CanCloneAttachments
  def content_type
    'text/html'
  end

  private

  def reordering_callback
    return if !category_id_changed? && !position_changed?

    # drop siblings cache to make sure ordering is always up to date
    category.answers.each(&:cache_delete)
  end
  before_save :reordering_callback

  class << self
    def attachment_to_hash(attachment)
      url = Rails.application.routes.url_helpers.attachment_path(attachment.id)

      {
        id:          attachment.id,
        url:         url,
        preview_url: "#{url}?preview=1",
        filename:    attachment.filename,
        size:        attachment.size,
        preferences: attachment.preferences
      }
    end
  end
end
