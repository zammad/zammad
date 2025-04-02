# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Answer < ApplicationModel
  include HasTranslations
  include HasAgentAllowedParams
  include HasTags
  include CanBePublished
  include ChecksKbClientNotification
  include ChecksKbClientVisibility
  include CanCloneAttachments

  AGENT_ALLOWED_ATTRIBUTES       = %i[category_id promoted internal_note].freeze
  AGENT_ALLOWED_NESTED_RELATIONS = %i[translations].freeze

  belongs_to :category, class_name: 'KnowledgeBase::Category', inverse_of: :answers, touch: true

  scope :include_contents, -> { eager_load(translations: :content) }
  scope :sorted,           -> { order(position: :asc) }

  scope :sorted_by_published, lambda {
    reorder(Arel.sql('GREATEST(knowledge_base_answers.published_at, knowledge_base_answers.updated_at) DESC'))
      .published
  }
  scope :sorted_by_internally_published, lambda {
    case ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
    when 'mysql2'
      reorder(Arel.sql('GREATEST(LEAST(IFNULL(knowledge_base_answers.internal_at,1), IFNULL(knowledge_base_answers.published_at, 1)), knowledge_base_answers.updated_at) DESC'))
    else
      reorder(Arel.sql('GREATEST(LEAST(knowledge_base_answers.internal_at, knowledge_base_answers.published_at), knowledge_base_answers.updated_at) DESC'))
    end
      .internal
  }

  acts_as_list scope: :category, top_of_list: 0

  # Provide consistent naming with KB category
  #
  # Originally this used alias_attribute. But alias_attribute for relations for deprecated in Rails 7.1 and removed in 7.2
  # However, alias_association was not merged in time for 7.2... So here is a workaround that will hopefully get removed in 7.3!
  #
  # Related PR: https://github.com/rails/rails/pull/49801
  alias parent category
  alias parent= category=

  alias assets_essential assets

  def attributes_with_association_ids
    attrs = super
    attrs[:attachments] = attachments_sorted.map { |elem| self.class.attachment_to_hash(elem) }
    attrs[:tags]        = tag_list
    attrs
  end

  def assets(data = {})
    return data if assets_added_to?(data)

    data = super
    data = category.assets(data)

    ApplicationModel::CanAssets.reduce(translations, data)
  end

  attachments_cleanup!

  def attachments_sorted
    attachments.sort_by { |elem| elem.filename.downcase }
  end

  def add_attachment(file)
    filename     = file.try(:original_filename) || File.basename(file.path)
    content_type = file.try(:content_type) || MIME::Types.type_for(filename).first&.content_type || 'application/octet-stream'

    Store.create!(
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

  def touch_translations
    translations
      .reject(&:destroyed?)
      .each(&:touch) # touch each translation separately to trigger after_commit callbacks
  end
  after_touch :touch_translations

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
