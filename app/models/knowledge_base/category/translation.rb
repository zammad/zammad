# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Category::Translation < ApplicationModel
  include HasAgentAllowedParams
  include HasSearchIndexBackend
  include KnowledgeBase::HasUniqueTitle

  AGENT_ALLOWED_ATTRIBUTES = %i[title kb_locale_id].freeze

  belongs_to :kb_locale, class_name: 'KnowledgeBase::Locale', inverse_of: :category_translations

  belongs_to :category,  class_name: 'KnowledgeBase::Category', inverse_of: :translations, touch: true

  validates :title,        presence: true
  validates :kb_locale_id, uniqueness: { case_sensitive: true, scope: :category_id }

  before_save :set_edited_at, if: :edited?

  # A category is dated by the content below it, so a title written here is an edit of every
  #   category this one is filed under as well. Creating the first translation of a brand-new
  #   category is the same event as filing that category under its parent, so this one hook covers
  #   both — KnowledgeBase::Category only has to bump on a *later* move.
  after_save :bump_parents_edited_at, if: :saved_change_to_title?

  scope :neighbours_of, ->(translation) { joins(:category).where(knowledge_base_categories: { parent_id: translation.category&.parent_id }) }

  # Moves the editorial timestamp of `category` and all its ancestors, in the given locales. The
  #   single place a bump is written, for every event that counts as an edit of a category's
  #   content (see the callbacks here, on KnowledgeBase::Category, KnowledgeBase::Answer and
  #   KnowledgeBase::Answer::Translation).
  #
  # Only the named locales move, and an ancestor without a row in one of them is simply not there
  #   to update: it is listed under a fallback title that an edit in this locale did not change.
  #
  # `#self_with_parents` is the cycle-safe recursive CTE, so a corrupt `parent_id` chain cannot spin
  #   here. The write is an `update_all` on purpose: one query whatever the depth of the tree, no
  #   validations against possibly invalid legacy rows, and no callbacks — which is what keeps this
  #   from recursing into itself through the `after_save` above.
  #
  # The trade-off of skipping callbacks: these rows are not reindexed, so their Elasticsearch
  #   `edited_at` lags behind until the row is next saved normally.
  #
  # @param category [KnowledgeBase::Category, nil] the lowest category to bump; nil is a no-op, so
  #   callers do not have to special-case a top-level category with no parent
  # @param kb_locale_ids [Array<Integer>] the locales the edit happened in
  def self.bump_edited_at(category, kb_locale_ids)
    return if category.nil? || kb_locale_ids.blank?

    where(category_id: category.self_with_parents.pluck(:id), kb_locale_id: kb_locale_ids)
      .update_all(edited_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
  end

  def to_param
    [category_id, title.parameterize].join('-')
  end

  def assets(data)
    return data if assets_added_to?(data)

    data = super
    category.assets(data)
  end

  def search_index_attribute_lookup(include_references: true)
    attrs = super

    attrs['title']    = ActionController::Base.helpers.strip_tags attrs['title']
    attrs['scope_id'] = category.parent_id

    attrs
  end

  scope :search_sql_text_fallback, lambda { |query|
    where_or_cis(%w[title], query)
  }

  scope :apply_kb_scope, lambda { |scope|
    if scope.present?
      joins(:category)
        .where(knowledge_base_categories: { parent_id: scope })
    end
  }

  private

  # What counts as an editorial change to a category, mirroring
  #   KnowledgeBase::Answer::Translation#edited? — the title is all a category translation carries.
  #   A `touch` (from a reorder, a sorting-mode switch or any save below the category) runs no
  #   callbacks at all, so it can never get here.
  def edited?
    return true if new_record?

    title_changed?
  end

  def set_edited_at
    self.edited_at = Time.zone.now
  end

  def bump_parents_edited_at
    self.class.bump_edited_at(category&.parent, [kb_locale_id])
  end
end
