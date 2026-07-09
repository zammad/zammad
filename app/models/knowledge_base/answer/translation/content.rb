# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Answer::Translation::Content < ApplicationModel
  include HasAgentAllowedParams
  include HasRichText

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

  def attributes_with_association_names(empty_keys: false)
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
    attrs['body'] = body_text_only
    attrs
  end

  def body_text_only
    body
      .gsub(%r{<br\s*/?>}i, "\n")
      .gsub(%r{<div\s*>}i, "\n")
      .then { ActionController::Base.helpers.strip_tags(it) }
  end

  private

  def sanitize_body
    self.body = HtmlSanitizer.dynamic_image_size(body)
  end

  before_save :sanitize_body

  def bump_translation_edited_at
    return if !translation.persisted?

    # The body is the translation's embedded content but lives on this separate record, so it never
    # shows up in the translation's own changes. Touch the translation so its reindex hook fires; a
    # body change also bumps edited_at (the editorial timestamp shown in the views).
    if saved_change_to_body?
      translation.touch(:edited_at) # rubocop:disable Rails/SkipsModelValidations
    else
      translation.touch # rubocop:disable Rails/SkipsModelValidations
    end
  end

  after_save :bump_translation_edited_at

  def touch_translation
    translation.touch # rubocop:disable Rails/SkipsModelValidations
  end

  after_touch :touch_translation
end
