# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Answer::Translation::Content < ApplicationModel
  include HasAgentAllowedParams
  include HasRichText
  include HasKnowledgeBaseAttachmentPermissions

  AGENT_ALLOWED_ATTRIBUTES = %i[body].freeze

  has_one :translation, class_name: 'KnowledgeBase::Answer::Translation', inverse_of: :content, dependent: :nullify

  has_rich_text :body

  attachments_cleanup!

  def visible?
    translation.answer.visible?
  end

  def visible_internally?
    translation.answer.visible_internally?
  end

  delegate :created_by_id, to: :translation

  def attributes_with_association_ids
    attrs = super
    add_attachments_to_attributes(attrs)
  end

  def attributes_with_association_names
    attrs = super
    add_attachments_to_attributes(attrs)
  end

  def add_attachments_to_attributes(attributes)
    attributes['attachments'] = attachments
                                .reject { |file| HasRichText.attachment_inline?(file) }
                                .map(&:attributes_for_display)

    attributes
  end

  def search_index_attribute_lookup(include_references: true)
    attrs = super
    attrs['body'] = ActionController::Base.helpers.strip_tags attrs['body']
    attrs
  end

  private

  def touch_translation
    translation&.touch # rubocop:disable Rails/SkipsModelValidations
  end

  before_save :sanitize_body
  after_save  :touch_translation
  after_touch :touch_translation

  def sanitize_body
    self.body = HtmlSanitizer.dynamic_image_size(body)
  end

end
