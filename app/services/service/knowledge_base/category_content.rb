# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Returns the browsable content of a single node in the knowledge base tree:
#   the breadcrumb path, the visible child categories, and their per-category
#   details (subtree answer/subcategory counts and content visibility), all
#   batched here and keyed by category id so the GraphQL type does not query
#   per category.
#
# `category` nil means the knowledge base root (only categories, no answers).
class Service::KnowledgeBase::CategoryContent < Service::Base
  attr_reader :knowledge_base, :category, :locale

  # `locale` is the resolved KnowledgeBase::Locale used to localize titles.
  def initialize(knowledge_base:, category: nil, locale: nil)
    @knowledge_base = knowledge_base
    @category = category
    @locale = locale
  end

  def execute
    {
      category:                     category,
      subcategories:                visible_child_categories,
      category_details:             category_details,
      category_titles:              category_titles,
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

  # Ancestor path of a category (root first, including itself), resolved from
  #   the in-memory tree so no parent-walk queries are needed.
  def trail_of(cat)
    trail = []
    node = cat
    while node
      trail.unshift(node)
      node = node.parent_id && by_id[node.parent_id]
    end
    trail
  end

  def by_id
    @by_id ||= all_categories.index_by(&:id)
  end

  # Breadcrumb (ancestor path) of the opened category and every rendered child,
  #   keyed by id, so the type resolves each `breadcrumb` field without a parent
  #   walk — and so a child's entry is cached for an instant header once opened.
  def category_breadcrumbs
    (visible_child_categories + [category].compact).to_h { |cat| [cat.id, trail_of(cat)] }
  end

  # Visible children of the current node (root when `category` is nil), resolved
  #   from the in-memory tree and the batched visibility set.
  def visible_child_categories
    @visible_child_categories ||= Array(children_by_parent[category&.id])
      .select { |child| visible_category_ids.include?(child.id) }
      .sort_by(&:position)
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
    localized_categories.to_h { |cat| [cat.id, preferred_title(translations_by_category[cat.id] || [])] }
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

  # Preferred translation title: requested locale, then the primary locale,
  #   then any translation.
  def preferred_title(translations)
    translation = (locale && translations.find { |t| t.kb_locale_id == locale.id }) ||
                  translations.find { |t| t.kb_locale_id == primary_kb_locale_id } ||
                  translations.first

    translation&.title
  end

  def primary_kb_locale_id
    @primary_kb_locale_id ||= knowledge_base.kb_locales.find_by(primary: true)&.id
  end

  # Per-category details (subtree answer/subcategory counts and content
  #   visibility) for every category shown in the payload — the rendered
  #   children and the breadcrumb (so the header has the current category's own
  #   counts) — keyed by category id.
  def category_details
    (visible_child_categories + breadcrumb).uniq(&:id).to_h do |cat|
      subtree = subtree_ids[cat.id]

      [cat.id, {
        answer_count:             subtree.sum { |id| visible_answer_counts[id].to_i },
        subcategory_count:        (subtree - [cat.id]).count { |id| visible_category_ids.include?(id) },
        direct_answer_count:      visible_answer_counts[cat.id].to_i,
        direct_subcategory_count: Array(children_by_parent[cat.id]).count { |child| visible_category_ids.include?(child.id) },
        visibility:               visibility_of(cat.id),
      }]
    end
  end

  def all_categories
    @all_categories ||= knowledge_base.categories.to_a
  end

  def children_by_parent
    @children_by_parent ||= all_categories.group_by(&:parent_id)
  end

  def all_category_ids
    @all_category_ids ||= all_categories.map(&:id)
  end

  # Category id => ids in its subtree (self first), resolved in memory from a
  #   single load of the tree.
  def subtree_ids
    @subtree_ids ||= {}.tap do |map|
      builder = lambda do |cat|
        map[cat.id] ||= [cat.id] + Array(children_by_parent[cat.id]).flat_map { |child| builder.call(child) }
      end

      all_categories.each { |cat| builder.call(cat) }
    end
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
                                category_ids_with_internal_subtree
                              else
                                category_ids_with_published_subtree
                              end
  end

  # Granular access with the locale gate: editor categories are always visible,
  #   reader/public ones only with matching (translated) content in the subtree.
  def granular_visible_category_ids
    accessible = KnowledgeBase::AccessibleCategories.for_user(current_user)

    Set.new(accessible.editor.map(&:id))
      .merge(accessible.reader.map(&:id).select { |id| category_ids_with_internal_subtree.include?(id) })
      .merge(accessible.public_reader.map(&:id).select { |id| category_ids_with_published_subtree.include?(id) })
  end

  # Highest content visibility of a category's subtree in the browsed locale
  #   (independent of the current user), mirroring the agent app: untranslated
  #   content does not count, so such categories show as draft.
  def visibility_of(id)
    if category_ids_with_published_subtree.include?(id)
      :published
    elsif category_ids_with_internal_subtree.include?(id)
      :internal
    elsif category_ids_with_archived_subtree.include?(id)
      :archived
    else
      :draft
    end
  end

  def category_ids_with_published_subtree
    @category_ids_with_published_subtree ||= category_ids_with_subtree_answers(:published)
  end

  def category_ids_with_internal_subtree
    @category_ids_with_internal_subtree ||= category_ids_with_subtree_answers(:internal)
  end

  def category_ids_with_archived_subtree
    @category_ids_with_archived_subtree ||= category_ids_with_subtree_answers(:archived)
  end

  # Ids of categories whose subtree contains at least one answer in the given
  #   publication scope (:internal, :published or :archived), translated to the
  #   browsed locale.
  def category_ids_with_subtree_answers(scope)
    answers = ::KnowledgeBase::Answer.public_send(scope)
    answers = answers.translated_to(locale) if locale

    direct = answers.where(category_id: all_category_ids).group(:category_id).count

    all_categories.each_with_object(Set.new) do |cat, set|
      set << cat.id if subtree_ids[cat.id].any? { |id| direct[id].to_i.positive? }
    end
  end
end
