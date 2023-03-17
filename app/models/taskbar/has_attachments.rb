# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Taskbar::HasAttachments
  extend ActiveSupport::Concern

  included do
    scope :with_form_id, -> { where("state LIKE '%form_id%'") }

    after_destroy :clear_attachments
  end

  # form_id is saved directly in a new ticket, but inside of the article when updating an existing ticket
  def persisted_form_id
    state&.dig(:form_id) || state&.dig(:article, :form_id)
  end

  private

  def attachments
    return [] if persisted_form_id.blank?

    UploadCache.new(persisted_form_id).attachments
  end

  def add_attachments_to_attributes(attributes)
    attributes.tap do |result|
      result['attachments'] = attachments.map(&:attributes_for_display)
    end
  end

  def clear_attachments
    return if persisted_form_id.blank?

    UploadCache.new(persisted_form_id).destroy
  end
end
