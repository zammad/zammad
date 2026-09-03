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

  # One mode per list: the subcategories of this category and the answers filed in it are ordered
  #   independently of each other (see KnowledgeBase::SORTING_MODES).
  validates :category_sorting_mode, inclusion: { in: KnowledgeBase::SORTING_MODES }
  validates :answer_sorting_mode,   inclusion: { in: KnowledgeBase::SORTING_MODES }

  before_validation :inherit_sorting_modes, on: :create

  # #inherit_sorting_modes needs to know whether the caller assigned these itself, and dirty
  #   tracking cannot answer that: it cannot tell an assignment equal to the column default from no
  #   assignment at all, so an editor explicitly choosing the default mode would otherwise read the
  #   same as one who never chose anything. Tracked here instead, independent of the value assigned.
  def category_sorting_mode=(value)
    @category_sorting_mode_assigned = true
    super
  end

  def answer_sorting_mode=(value)
    @answer_sorting_mode_assigned = true
    super
  end

  validate :cannot_be_child_of_parent, :parent_must_reach_root, :cannot_exceed_max_depth

  scope :root,   -> { where(parent: nil) }
  scope :sorted, -> { order(position: :asc) }

  # Orders the categories listed inside one node in that node's `category_sorting_mode`. The single
  #   place that order is decided for either stack: the help site orders a listing with it directly
  #   (KnowledgeBase::Public::BaseController#categories_filter), and the desktop view loads its
  #   whole tree through it (Service::KnowledgeBase::Concerns::WalksCategoryTree#all_categories),
  #   so neither sorts categories in Ruby.
  #
  # That matters for anything outside ASCII. Ruby compares strings by codepoint, which files every
  #   accented title after `Z` ("Ähre" after "Zebra"); PostgreSQL applies the database collation,
  #   which folds it onto its base letter ("Ähre" before "apple"). Deciding it here once means the
  #   two interfaces cannot disagree about it. As elsewhere in Zammad (see Transaction::Trigger),
  #   the exact order of non-ASCII titles is the database's collation to define.
  #
  # `last_update` dates a category by the `edited_at` of the translation it is shown under, the way
  #   the answer listing dates an answer by the `edited_at` of its own — one editorial timestamp per
  #   locale, moved by a real edit and by nothing else (KnowledgeBase::Category::Translation
  #   .bump_edited_at, and the callbacks that call it). Deliberately not the record's own
  #   `updated_at`: `touch: true` runs up the tree from every answer save, and a reorder or a
  #   sorting-mode switch writes the category too, so an `updated_at` proxy floats a category to the
  #   top of a "last update" listing for changes nobody would call an edit.
  #
  # `NULLS LAST` covers the one case the timestamp cannot answer for: a category with no translation
  #   at all, whose correlated subquery is null. It goes last rather than being read as 1970.
  #
  # The id is the tie-breaker in every mode: positions are not unique-constrained, and titles and
  #   timestamps can collide just as well.
  scope :sorted_by_mode, lambda { |mode, system_locale_or_id: nil|
    case mode
    when 'alphabetical'
      reorder(Arel.sql("LOWER(#{preferred_translation_sql(:title, system_locale_or_id)}) ASC, knowledge_base_categories.id ASC"))
    when 'last_update'
      reorder(Arel.sql("#{preferred_translation_sql(:edited_at, system_locale_or_id)} DESC NULLS LAST, knowledge_base_categories.id ASC"))
    else
      reorder(position: :asc, id: :asc)
    end
  }

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

  # The value of one column of the translation the category is *shown* under, as a scalar subquery
  #   usable in ORDER BY, with the same three-level fallback as
  #   Service::KnowledgeBase::CategoryContent#preferred_translation (requested locale, then the
  #   primary locale, then any). See KnowledgeBase::Answer.preferred_translation_sql for why this
  #   is a correlated subquery and why it is keyed on the system locale.
  def self.preferred_translation_sql(column, system_locale_or_id)
    ActiveRecord::Base.sanitize_sql_array(
      [
        <<~SQL.squish,
          (SELECT translations.#{connection.quote_column_name(column)}
             FROM knowledge_base_category_translations translations
            WHERE translations.category_id = knowledge_base_categories.id
            ORDER BY (translations.kb_locale_id IN (:browsed)) DESC, (translations.kb_locale_id IN (:primary)) DESC, translations.id ASC
            LIMIT 1)
        SQL
        ::KnowledgeBase::Locale.translation_preference_ids(system_locale_or_id),
      ]
    )
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

  # Ids of every category kept out of the vector index: the configured ones plus their whole
  # subtrees. Empty by default (#6248), since the index covers everything unless told otherwise.
  #
  # Exclusions are inherited, so excluding a category takes its whole subtree out of the index —
  # moving a category under an excluded one excludes it too.
  def self.vector_excluded_category_ids
    excluded_category_ids = vector_excluded_setting_ids
    return [] if excluded_category_ids.blank?

    # Excluding both a category and something below it makes the subtrees overlap, hence the
    # #distinct — and the CTE's default depth ordering has to go first, since PostgreSQL rejects
    # DISTINCT alongside an ORDER BY expression that #pluck leaves out of the SELECT list.
    with_recursive_tree_cte(direction: :down, seed: where(id: excluded_category_ids))
      .reorder(nil)
      .distinct
      .pluck(:id)
  end

  # Whether the given category's answers belong in the vector index — the single-category question,
  # answered from the same expanded id list as the bulk one.
  #
  # Walking down from the excluded roots once costs no more than walking up from the candidate (the
  # category tree is small and the query round-trip dominates, whatever the subtree size), so there
  # is no second, ancestor-walking implementation to keep in step with this one.
  #
  # @param category_or_id [KnowledgeBase::Category, Integer, String, nil] a persisted category or its
  #   id, so callers holding only an id (e.g. an answer's category_id) do not have to load the record
  def self.vector_indexable?(category_or_id)
    vector_excluded_category_ids.exclude?(category_or_id.try(:id) || category_or_id.to_i)
  end

  def self.vector_excluded_setting_ids
    Array
      .wrap(Setting.get('vectordb_knowledge_base_excluded_category_ids'))
      .filter_map { Integer(it, exception: false) }
      .select(&:positive?)
  end
  private_class_method :vector_excluded_setting_ids

  # Index the subtree when a move brings it out of an excluded branch — those answers have no
  # documents yet, and nothing else would ever create them.
  #
  # The opposite direction is deliberately not handled: a move *into* an excluded branch leaves the
  # existing documents behind, but the search filters hits by category anyway
  # (Service::KnowledgeBase::Answer::SimilaritySearch), so they cannot surface. Purging them is not
  # worth fanning out over the whole subtree — each answer drops its own document the next time it
  # is edited, and a rebuild clears the rest.
  #
  # Both checks are asked of the two categories involved rather than of every answer below them.
  # Reading the new state off `self` (not off `parent_id`) also covers a category excluded in its own
  # right: its subtree stays out wherever it hangs, so there is nothing to index.
  def vector_index_resync_subtree
    return if !Service::AI::VectorDB::Available.execute(ping: false)
    return if !self.class.vector_indexable?(self)
    return if self.class.vector_indexable?(saved_change_to_parent_id.first)

    VectorIndexKnowledgeBaseCategoryResyncJob.perform_later(self)
  end
  after_update_commit :vector_index_resync_subtree, if: :saved_change_to_parent_id?

  # Moving a subtree under another category changes what that category holds, so it counts as an
  #   edit of the new parent and of everything above it — in every locale the moved category is
  #   translated to, since the whole subtree moved.
  #
  # The moved category itself is not bumped: being moved is not being edited. Neither is the parent
  #   it came out of, for the same reason KnowledgeBase::Answer#bump_category_edited_at leaves the
  #   old category alone. A move to the top level has no new parent and is a no-op.
  #
  # Keyed on the same change as the resync above, and deliberately not on `after_update_commit`: the
  #   bump belongs in the transaction that moved the category.
  def bump_parent_edited_at
    Translation.bump_edited_at(parent, translations.map(&:kb_locale_id))
  end
  after_update :bump_parent_edited_at, if: :saved_change_to_parent_id?

  # The knowledge base's asset cache keeps its `category_ids` until its own `updated_at` changes
  # (ApplicationModel::CanAssociations#attributes_with_association_ids), and adding or removing a
  # category does not touch it — so without dropping that entry here, clients keep being served a
  # category list from before this category existed. The admin interface reads exactly that list to
  # decide whether an icon set switch has icons to reset, and `touch: true` on the association is no
  # alternative: it would fire the knowledge base's own callbacks and notifications on every
  # category write.
  def invalidate_knowledge_base_asset_cache
    knowledge_base&.cache_delete
  end
  after_commit :invalidate_knowledge_base_asset_cache, on: %i[create destroy]

  # Moving a category to another knowledge base (`knowledge_base_id` is agent-writable) takes it off
  # one category list and puts it on another, so both sides go stale.
  def invalidate_knowledge_base_asset_caches_after_move
    invalidate_knowledge_base_asset_cache

    KnowledgeBase.find_by(id: saved_change_to_knowledge_base_id.first)&.cache_delete
  end
  after_update_commit :invalidate_knowledge_base_asset_caches_after_move, if: :saved_change_to_knowledge_base_id?

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

  def archived_content?(kb_locale = nil)
    scope = self_with_children_answers.archived

    scope = scope.localed(kb_locale.system_locale) if kb_locale

    scope.any?
  end

  # Highest publication state of this category's subtree content in the given
  #   locale, expressed with the CanBePublished state vocabulary for color-coding.
  def content_visibility(kb_locale = nil)
    if public_content?(kb_locale)
      :published
    elsif internal_content?(kb_locale)
      :internal
    elsif archived_content?(kb_locale)
      :archived
    else
      :draft
    end
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

  # A new category follows the list it lands in: an editor who set a category's subcategories to
  #   alphabetical gets alphabetical subcategories under it, rather than a hand-made order with
  #   nothing arranged behind it. The two lists are independent (see KnowledgeBase::SORTING_MODES),
  #   so they inherit independently — the subcategories can follow the parent while the answers stay
  #   where the parent put them.
  #
  # A top level category has no answer mode above it to inherit: the knowledge base root lists
  #   categories only. Its answers therefore take KnowledgeBase::DEFAULT_SORTING_MODE rather than
  #   the root's *category* mode, which would conflate two lists the model keeps deliberately
  #   apart.
  #
  # Create time only, like #category_icon: moving a category under a different parent keeps the
  #   modes it has, since an editor either chose them or accepted them and re-deriving would
  #   silently rewrite that.
  #
  # The guards go by whether the caller assigned the attribute at all (see the writer overrides
  #   above), not by dirty tracking, so an explicit assignment always wins over inheritance —
  #   including an explicit `alphabetical` on a category under a `manual` parent.
  def inherit_sorting_modes
    # Nothing to inherit from yet — `belongs_to :knowledge_base` reports the missing node itself.
    return if (source = parent || knowledge_base).nil?

    self.category_sorting_mode = source.category_sorting_mode if !@category_sorting_mode_assigned
    self.answer_sorting_mode   = parent&.answer_sorting_mode || KnowledgeBase::DEFAULT_SORTING_MODE if !@answer_sorting_mode_assigned
  end

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
