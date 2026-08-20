# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Parent options for the knowledge base category form: the tree of categories the current user
#   may create a category under.
#
# The top level is deliberately not an option. The form's parent field is clearable, and an empty
#   selection is what means "top level" — offering the knowledge base as a row too would give the
#   same choice two representations. Whether the top level may be picked at all is still this
#   class's business, see #top_level_selectable?.
#
# Shares the nested `{ value, label, children }` option shape with
#   FormUpdater::Relation::Group, but not its disabled-node handling: every node offered here is
#   a permitted parent, so there is nothing to render as unselectable. Tree-shape rules (own
#   subtree, nesting depth) stay with the model validations at save time.
#
# The exclusions are why this is not driven through the generic `relation_fields` mechanism —
#   they depend on the category being edited and on the current user, neither of which
#   FormUpdater::Updater#get_relation_resolver can pass. It is instantiated directly by the
#   updater instead, like FormUpdater::Concerns::HasUserPermissions does with Relation::Group.
class FormUpdater::Relation::KnowledgeBaseCategoryParent < FormUpdater::Relation
  attr_reader :knowledge_base, :excluded_category, :kb_locale

  # @param knowledge_base [KnowledgeBase] the knowledge base the category belongs to
  # @param excluded_category [KnowledgeBase::Category, nil] the category being edited; it and its
  #   whole subtree are not valid parents for itself. Nil when adding a category.
  # @param kb_locale [KnowledgeBase::Locale, nil] locale to render titles in
  def initialize(knowledge_base:, excluded_category: nil, kb_locale: nil, **)
    super(**)

    @knowledge_base    = knowledge_base
    @excluded_category = excluded_category
    @kb_locale         = kb_locale
  end

  def options
    options_tree(root_categories)
  end

  # Creating a top level category means creating it under the knowledge base, which
  #   CategoryPolicy#create? allows only for an editor of the knowledge base itself — so a
  #   granular editor who is locked out of it may not clear the parent field.
  def top_level_selectable?
    return @top_level_selectable if defined?(@top_level_selectable)

    @top_level_selectable = if granular_permissions?
                              ::KnowledgeBase::EffectivePermission
                                .new(current_user, knowledge_base)
                                .access_effective
                                .eql?('editor')
                            else
                              global_editor?
                            end
  end

  # Categories the user may create under: the ones they have editor access to, minus the edited
  #   subtree. Public so the updater can resolve a submitted parent against the same set it
  #   offered, instead of trusting the form's value.
  def selectable_categories
    @selectable_categories ||= editor_categories
      .reject { |category| excluded_ids.include?(category.id) }
      .sort_by(&:position)
  end

  private

  # Without a single granular permission row, effective access falls through to the role
  #   defaults, so every category is an editor one for a knowledge_base.editor — one indexed
  #   query instead of the AccessibleCategories sweep over all knowledge bases.
  def editor_categories
    if !granular_permissions?
      return global_editor? ? knowledge_base.categories.to_a : []
    end

    ::KnowledgeBase::AccessibleCategories
      .for_user(current_user)
      .editor
      .select { |category| category.knowledge_base_id == knowledge_base.id }
  end

  def granular_permissions?
    return @granular_permissions if defined?(@granular_permissions)

    @granular_permissions = ::KnowledgeBase.granular_permissions?
  end

  def global_editor?
    current_user.permissions?('knowledge_base.editor')
  end

  def relation_type
    ::KnowledgeBase::Category
  end

  def excluded_ids
    @excluded_ids ||= excluded_category ? excluded_category.self_with_children_ids.to_set : Set.new
  end

  def usable_ids
    @usable_ids ||= selectable_categories.to_set(&:id)
  end

  # A usable category whose parent is not itself usable starts a tree, so a category stays
  #   reachable even when an ancestor is excluded (e.g. a granular editor with access to a
  #   subcategory but not to its parent).
  def root_categories
    selectable_categories.select { |category| category.parent_id.nil? || usable_ids.exclude?(category.parent_id) }
  end

  # Also holds groups nobody renders (under nil, or under a parent that is not offered — those
  #   members are the promoted roots): #options_tree only ever looks up offered ids.
  def children_by_parent
    @children_by_parent ||= selectable_categories.group_by(&:parent_id)
  end

  def options_tree(categories)
    categories.map do |category|
      option = { value: category.id, label: display_name(category) }
      children = options_tree(children_by_parent[category.id] || [])
      option[:children] = children if children.any?

      option
    end
  end

  def display_name(category)
    # Without a locale there is nothing to batch on; only reachable for a knowledge base without
    #   locales, which `validates :kb_locales, presence: true` rules out.
    return category.translation_preferred(kb_locale)&.title if kb_locale.nil?

    titles[[category.id, kb_locale.id]]&.title
  end

  # One query for every title, instead of a translation lookup per node.
  def titles
    @titles ||= ::KnowledgeBase::Category.preferred_translations_for(
      selectable_categories.map { |category| [category.id, kb_locale.id] }
    )
  end
end
