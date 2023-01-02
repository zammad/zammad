# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Category < ApplicationModel
  include HasTranslations
  include HasAgentAllowedParams
  include ChecksKbClientNotification
  include ChecksKbClientVisibility

  AGENT_ALLOWED_ATTRIBUTES       = %i[knowledge_base_id parent_id category_icon].freeze
  AGENT_ALLOWED_NESTED_RELATIONS = %i[translations].freeze

  belongs_to :knowledge_base, inverse_of: :categories

  has_many   :answers,   class_name: 'KnowledgeBase::Answer',
                         inverse_of: :category,
                         dependent:  :restrict_with_exception

  has_many   :children,  class_name:  'KnowledgeBase::Category',
                         foreign_key: :parent_id,
                         inverse_of:  :parent,
                         dependent:   :restrict_with_exception

  belongs_to :parent,    class_name: 'KnowledgeBase::Category',
                         inverse_of: :children,
                         touch:      true,
                         optional:   true

  has_many :permissions, class_name: 'KnowledgeBase::Permission',
                         as:         :permissionable,
                         autosave:   true,
                         dependent:  :destroy

  validates :category_icon, presence: true

  scope :root,   -> { where(parent: nil) }
  scope :sorted, -> { order(position: :asc) }

  acts_as_list scope: :parent, top_of_list: 0

  alias assets_essential assets

  def assets(data = {})
    return data if assets_added_to?(data)

    data = super(data)
    data = knowledge_base.assets(data)

    data = ApplicationModel::CanAssets.reduce(translations, data)

    # include parent category or KB for root to have full path
    (parent || knowledge_base).assets(data)
  end

  def self_parent?(candidate)
    return true if candidate == parent
    return true if parent&.self_parent?(candidate)
  end

  def self_with_children
    [self] + children.map(&:self_with_children).flatten
  end

  def self_with_parents
    result = [self]

    check = self
    while check.parent.present?
      result << check.parent
      check = check.parent
    end

    result
  end

  def self_with_children_answers
    KnowledgeBase::Answer.where(category_id: self_with_children_ids)
  end

  def self_with_children_ids
    output = [id]

    output << KnowledgeBase::Category.where(parent_id: output.last).pluck(:id) while output.last.present?

    output.flatten
  end

  def full_destroy!
    transaction do
      answers.each(&:destroy!)
      answers.reset
      children.reset
      destroy!
    end
  end

  def public_content?(kb_locale = nil)
    scope = self_with_children_answers.published

    scope = scope.localed(kb_locale.system_locale) if kb_locale

    scope.any?
  end

  def internal_content?(kb_locale = nil)
    scope = self_with_children_answers.internal

    scope = scope.localed(kb_locale.system_locale) if kb_locale

    scope.any?
  end

  def visible?(kb_locale = nil)
    public_content?(kb_locale)
  end

  def api_url
    Rails.application.routes.url_helpers.knowledge_base_category_path(knowledge_base, self)
  end

  def permissions_effective
    cache_key = KnowledgeBase::Permission.cache_key self

    Rails.cache.fetch cache_key do
      KnowledgeBase::Category::Permission.new(self).permissions_effective
    end
  end

  def attributes_with_association_ids
    attrs = super
    attrs[:permissions_effective] = permissions_effective
    attrs
  end

  private

  def cannot_be_child_of_parent
    errors.add(:parent_id, 'cannot be a child of the parent') if self_parent?(self)
  end
  validate :cannot_be_child_of_parent

  def sibling_categories
    parent&.children || knowledge_base.categories.root
  end
end
