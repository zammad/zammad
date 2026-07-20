# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Category < ApplicationModel
  include HasTranslations
  include HasAgentAllowedParams
  include ChecksKbClientNotification
  include ChecksKbClientVisibility
  include HasRecursiveCteQuery
  include TriggersKnowledgeBaseContentUpdates

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

  validate :cannot_be_child_of_parent, :parent_must_reach_root, :cannot_exceed_max_depth

  scope :root,   -> { where(parent: nil) }
  scope :sorted, -> { order(position: :asc) }

  acts_as_list scope: :parent, top_of_list: 0

  alias assets_essential assets

  def assets(data = {})
    return data if assets_added_to?(data)

    data = super
    data = knowledge_base.assets(data)

    data = ApplicationModel::CanAssets.reduce(translations, data)

    # include parent category or KB for root to have full path
    (parent || knowledge_base).assets(data)
  end

  # Whether `candidate` is among this category's ancestors. Checks the (possibly just assigned,
  # unsaved) `parent` in memory first, then walks the rest of the chain with the cycle-safe CTE of
  # #self_with_parents — plain Ruby recursion here would never terminate on an already-corrupted
  # tree containing a parent_id cycle, turning every validation of an affected category into a
  # SystemStackError.
  def self_parent?(candidate)
    return false if parent.nil?
    return true  if candidate == parent

    parent.self_with_parents.exists?(id: candidate.id)
  end

  def self.max_depth
    100
  end

  # Returns self and all descendants (any depth) as a single relation, using a recursive CTE
  # instead of one query per node. A `path` column guards against infinite recursion if a cycle
  # ever slips into `parent_id` (e.g. via a validation bypass), matching PostgreSQL's recommended
  # cycle-detection pattern for `WITH RECURSIVE` (native `CYCLE` support requires PostgreSQL 14+,
  # but Zammad supports 13+).
  def self_with_children
    self.class.with_recursive_tree_cte(direction: :down, seed: self)
  end

  # Returns all descendants (any depth), excluding self. See #self_with_children for cycle-safety
  # notes.
  def all_children
    self_with_children.where.not(id: id)
  end

  # Returns self and all ancestors (any depth), ordered from self up to the root, using a
  # recursive CTE instead of one query per level. See #self_with_children for cycle-safety notes.
  def self_with_parents
    self.class.with_recursive_tree_cte(direction: :up, seed: self)
  end

  def self_with_children_answers
    KnowledgeBase::Answer.where(category_id: self_with_children_ids)
  end

  # Returns the ids of self and all descendants (any depth), shallowest first. See
  # #self_with_children for cycle-safety notes — the per-level loop this replaces had no iteration
  # bound at all, so a parent_id cycle made it loop forever.
  def self_with_children_ids
    self_with_children.pluck(:id)
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

  # Whether this category is visible to the given user when browsing, mirroring
  #   KnowledgeBase::Answer.visible_to_user (editor: all, reader: internally
  #   published content, granular: per-permission, everyone else: public content).
  #   With a kb_locale, non-editors only count content translated to that locale,
  #   like the agent app (editors also see untranslated content).
  def visible_to_user?(user, kb_locale = nil)
    case KnowledgeBase.access_for_user(user)
    when :editor
      true
    when :reader
      internal_content?(kb_locale)
    when :granular
      granular_visible_to_user?(user, kb_locale)
    else
      public_content?(kb_locale)
    end
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

  # Mirrors KnowledgeBase::AccessibleCategories#taxonomize_category, with the
  #   locale gate applied to the content-based (non-editor) accesses.
  def granular_visible_to_user?(user, kb_locale)
    case KnowledgeBase::EffectivePermission.new(user, self).access_effective
    when 'editor'
      true
    when 'reader'
      internal_content?(kb_locale)
    when 'public_reader'
      public_content?(kb_locale)
    else
      false
    end
  end

  def cannot_be_child_of_parent
    errors.add(:parent_id, __('cannot be a subcategory of the parent category')) if self_parent?(self)
  end

  # Rejects a parent whose own ancestry never terminates at a root — i.e. one inside an existing
  # parent_id cycle (corrupt data; normally impossible thanks to #cannot_be_child_of_parent).
  # Such a chain looks finite to the cycle-guarded walk in #self_with_parents, so without this
  # check the category would silently join the corrupt component. Mirrors
  # Group#check_parent_reaches_root.
  #
  # Guards on the association, not just parent_id: a request naming a deleted or nonexistent
  # parent_id leaves `parent` nil, and that case belongs to the foreign-key constraint at save
  # time (mapped to 422), not to a NoMethodError here.
  def parent_must_reach_root
    return if !parent_id_changed?
    return if parent.nil?

    topmost = parent.self_with_parents.last
    return if topmost.nil? || topmost.parent_id.blank?

    errors.add(:parent_id, __('is part of a circular reference'))
  end

  # Rejects creating or moving a category where it (or, when moving a subtree, one of its
  # descendants) would end up beyond .max_depth. Mirrors Group#check_max_depth: `all_children`'s
  # tracked depth is relative to self (1 at direct children, self itself being 0), so a
  # descendant's depth-after-save is `new_depth + relative_depth`. Only runs when parent_id
  # actually changes, so already-too-deep trees (e.g. imported before this limit existed) can
  # still save unrelated attribute updates.
  def cannot_exceed_max_depth
    return if !parent_id_changed? || parent.nil?

    new_depth = parent.self_with_parents.count

    return errors.add(:parent_id, __('would exceed the allowed nesting depth')) if new_depth >= self.class.max_depth

    deepest_relative_depth = all_children.maximum(self.class.recursive_tree_depth_column)
    return if deepest_relative_depth.nil? || new_depth + deepest_relative_depth < self.class.max_depth

    errors.add(:parent_id, __("would push this category's children beyond the allowed nesting depth"))
  end

  def sibling_categories
    parent&.children || knowledge_base.categories.root
  end
end
