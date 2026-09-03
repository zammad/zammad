# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Returns the browsable content of a single node in the knowledge base tree:
#   the breadcrumb path, the visible child categories, and their per-category
#   details (subtree answer/subcategory counts and content visibility), all
#   batched here and keyed by category id so the GraphQL type does not query
#   per category.
#
# `category` nil means the knowledge base root (only categories, no answers).
class Service::KnowledgeBase::CategoryContent < Service::Base
  include Service::KnowledgeBase::Concerns::WalksCategoryTree

  attr_reader :knowledge_base, :category, :locale, :sorting_mode

  # `locale` is the resolved KnowledgeBase::Locale used to localize titles.
  #
  # `sorting_mode` overrides the node's stored `category_sorting_mode` for this listing alone,
  #   which is what lets the sorting bar preview a mode before it is saved. One of
  #   KnowledgeBase::SORTING_MODES; nil (the normal case) lists in the stored mode.
  def initialize(knowledge_base:, category: nil, locale: nil, sorting_mode: nil)
    @knowledge_base = knowledge_base
    @category = category
    @locale = locale
    @sorting_mode = sorting_mode
  end

  def execute
    {
      category:                     category,
      subcategories:                visible_child_categories,
      category_details:             category_details,
      category_titles:              category_titles,
      category_edited_at:           category_edited_at,
      category_translation_missing: category_translation_missing,
      category_breadcrumbs:         category_breadcrumbs,
    }
  end

  private

  # The opened category's own trail; also drives which ancestors the title and
  #   visibility batches must cover.
  def breadcrumb
    @breadcrumb ||= category.nil? ? [] : trail_of(category)
  end

  # Breadcrumb (ancestor path) of the opened category and every rendered child,
  #   keyed by id, so the type resolves each `breadcrumb` field without a parent
  #   walk — and so a child's entry is cached for an instant header once opened.
  def category_breadcrumbs
    (visible_child_categories + [category].compact).to_h { |cat| [cat.id, trail_of(cat)] }
  end

  # Visible children of the current node (root when `category` is nil), in the
  #   node's category sorting mode, resolved against the loaded tree and the
  #   batched visibility set.
  def visible_child_categories
    @visible_child_categories ||= ordered_child_ids
      .filter_map { |id| categories_by_id[id] }
      .select { |child| visible_category_ids.include?(child.id) }
  end

  # The children in display order, as ids only. The order is settled by the
  #   database rather than in Ruby, which compares strings by codepoint and would
  #   file every non-ASCII title after `Z`, disagreeing with the order the help
  #   site renders from the same data (KnowledgeBase::Category.sorted_by_mode).
  #
  # Only the ids: the records themselves are already loaded with the tree, so
  #   this asks the database to arrange one node's children and nothing more.
  def ordered_child_ids
    @ordered_child_ids ||= child_scope
      .sorted_by_mode(sorting_mode || node_category_sorting_mode, system_locale_or_id: locale&.system_locale_id)
      .pluck(:id)
  end

  def child_scope
    category&.children || knowledge_base.categories.root
  end

  # Stored sorting mode of the *categories* listed in the browsed node: the opened
  #   category's, or the knowledge base's own at the root, which lists categories
  #   just the same. The answers of the same category are listed by
  #   Service::KnowledgeBase::Answers, in the mode of their own.
  def node_category_sorting_mode
    (category || knowledge_base).category_sorting_mode
  end

  # Categories shown in the payload (breadcrumb + children), whose titles and
  #   translation state are resolved from a single translation load.
  def localized_categories
    @localized_categories ||= (breadcrumb + visible_child_categories).uniq
  end

  # Translations of every shown category, keyed by category id, loaded once and
  #   reused for both the localized titles and the missing-translation flags.
  def translations_by_category
    @translations_by_category ||= ::KnowledgeBase::Category::Translation
      .where(category_id: localized_categories.map(&:id))
      .group_by(&:category_id)
  end

  # Localized titles for every category shown in the payload (breadcrumb +
  #   children), keyed by category id, mirroring
  #   KnowledgeBase::Category#translation_preferred.
  def category_titles
    localized_categories.to_h { |cat| [cat.id, preferred_translation(translations_by_category[cat.id] || [])&.title] }
  end

  # Editorial timestamp of the same translation each category is shown under, keyed by category id,
  #   so the listing does not cost one query per category to date its cards. Nil for a category
  #   without a single translation, exactly as its title is.
  def category_edited_at
    localized_categories.to_h { |cat| [cat.id, preferred_translation(translations_by_category[cat.id] || [])&.edited_at] }
  end

  # Whether each shown category lacks its own translation in the browsed locale
  #   (so its title falls back to the primary/any locale), keyed by category id.
  #   With no locale requested nothing counts as missing.
  def category_translation_missing
    localized_categories.to_h do |cat|
      translations = translations_by_category[cat.id] || []
      [cat.id, locale.present? && translations.none? { |t| t.kb_locale_id == locale.id }]
    end
  end

  # The translation a category is shown under: requested locale, then the primary locale, then any.
  #   Mirrors KnowledgeBase::Category#translation_preferred, resolved from the single load above —
  #   and the fallback chain KnowledgeBase::Category.preferred_translation_sql expresses for the
  #   listing's own ORDER BY, so what dates a card and what orders it are the same row.
  def preferred_translation(translations)
    (locale && translations.find { |t| t.kb_locale_id == locale.id }) ||
      translations.find { |t| t.kb_locale_id == primary_kb_locale_id } ||
      translations.first
  end

  def primary_kb_locale_id
    @primary_kb_locale_id ||= knowledge_base.kb_locales.find_by(primary: true)&.id
  end

  # Per-category details (subtree answer/subcategory counts and content
  #   visibility) for every category shown in the payload — the rendered
  #   children and the breadcrumb (so the header has the current category's own
  #   counts) — keyed by category id.
  def category_details
    (visible_child_categories + breadcrumb).uniq(&:id).to_h { |cat| [cat.id, detail_of(cat.id)] }
  end

  def detail_of(id)
    {
      answer_count:             subtree_answer_count(id),
      subcategory_count:        subtree_subcategory_count(id),
      direct_answer_count:      visible_answer_counts[id].to_i,
      direct_subcategory_count: visible_children_count(id),
      visibility:               content_visibility(id),
      deletable:                empty_category?(id),
    }
  end

  def subtree_answer_count(id)
    subtree_ids(id).sum { |subtree_id| visible_answer_counts[subtree_id].to_i }
  end

  def subtree_subcategory_count(id)
    (subtree_ids(id) - [id]).count { |subtree_id| visible_category_ids.include?(subtree_id) }
  end

  def visible_children_count(id)
    Array(children_by_parent[id]).count { |child| visible_category_ids.include?(child.id) }
  end

  # Answers visible to the current user, counted per category. Visibility —
  #   including whether archived answers are counted — is delegated to
  #   KnowledgeBase::Answer.visible_to_user: editors count all answers in their
  #   categories (draft and archived included), while non-editors only count
  #   published/internal content, never archived.
  #   Locale-gated for non-editors: like the agent app, readers only see answers
  #   translated to the browsed locale, while editors also see untranslated ones.
  def visible_answer_counts
    @visible_answer_counts ||= ::KnowledgeBase::Answer
      .visible_to_user(current_user, kb_locale: locale)
      .where(category_id: all_category_ids)
      .group(:category_id)
      .count
  end

  # Whether a category holds nothing at all, which is what `destroy!` requires — the
  #   backing data for `isDeletable`.
  def empty_category?(id)
    Array(children_by_parent[id]).empty? && total_answer_counts[id].nil?
  end

  # Answers per category regardless of visibility, for the emptiness check above:
  #   `destroy!` is refused by any answer below the category, including ones the current
  #   user may not see — so the visible counts above cannot answer it.
  def total_answer_counts
    @total_answer_counts ||= ::KnowledgeBase::Answer
      .where(category_id: all_category_ids)
      .group(:category_id)
      .count
  end

  # Ids of categories visible to the current user when browsing, mirroring
  #   KnowledgeBase::Category#visible_to_user? but computed in one batch. The
  #   content-based cases (reader/granular-non-editor/public) are locale-gated
  #   through the subtree sets.
  def visible_category_ids
    @visible_category_ids ||= case KnowledgeBase.access_for_user(current_user)
                              when :editor
                                all_category_ids.to_set
                              when :granular
                                granular_visible_category_ids
                              when :reader
                                category_ids_with_subtree_answers(:internal)
                              else
                                category_ids_with_subtree_answers(:published)
                              end
  end

  # Granular access with the locale gate: editor categories are always visible,
  #   reader/public ones only with matching (translated) content in the subtree.
  def granular_visible_category_ids
    accessible = KnowledgeBase::AccessibleCategories.for_user(current_user)

    Set.new(accessible.editor.map(&:id))
      .merge(accessible.reader.map(&:id).select { |id| category_ids_with_subtree_answers(:internal).include?(id) })
      .merge(accessible.public_reader.map(&:id).select { |id| category_ids_with_subtree_answers(:published).include?(id) })
  end
end
