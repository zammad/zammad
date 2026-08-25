# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The shared body of the category create and edit form updaters: the parent selection resolved
#   through FormUpdater::Relation::KnowledgeBaseEditorCategory, on top of the permission matrix
#   every knowledge base form offers.
#
# The reason the whole form goes through an updater is the parent → permissions dependency:
#   which access levels a role may be given depends on what it inherits from the selected
#   parent, so the permission rows are re-resolved against `data['parentId']` on every change
#   rather than only at mount.
#
# Includers provide #knowledge_base, #excluded_category, #initial_parent_value and
#   #fallback_parent, and may override #stored_permissions.
module FormUpdater::Updater::KnowledgeBase::Category::Concerns::HasParentAndPermissions
  extend ActiveSupport::Concern

  include FormUpdater::Updater::KnowledgeBase::Concerns::HasPermissionsField

  def object_type
    ::KnowledgeBase::Category
  end

  def resolve
    result['parentId'] = parent_id_field

    super
  end

  private

  def kb_locale
    @kb_locale ||= ::KnowledgeBase::Locale.preferred(current_user, knowledge_base)
  end

  def parent_relation
    @parent_relation ||= FormUpdater::Relation::KnowledgeBaseEditorCategory.new(
      context:           context,
      current_user:      current_user,
      data:              data,
      knowledge_base:    knowledge_base,
      excluded_category: excluded_category,
      kb_locale:         kb_locale,
    )
  end

  # Options are refreshed on every run, but the parent value is only the *initial* one —
  #   resending it later would overwrite whatever the user has picked since.
  #
  # An empty field means the top level, so a user who may not create there must not be able to
  #   clear it: the field goes out as required instead, which the form enforces before it ever
  #   submits. The mutation still decides for real — this only saves the round trip that would
  #   come back forbidden.
  def parent_id_field
    field = { options: parent_relation.options, required: !parent_relation.top_level_selectable? }

    initial = meta[:initial] ? initial_parent_value : nil
    field[:initialValue] = initial if !initial.nil?

    field
  end

  # A category inherits from the parent currently picked in the form.
  def permissions_parent
    selected_parent
  end

  # What the category would inherit from: the parent currently picked in the form, falling back
  #   to what the includer considers current.
  def selected_parent
    submitted_parent || fallback_parent
  end

  # Category ids are resolved against the options that were actually offered, so the permissions
  #   of a category the user has no access to cannot be read out by submitting its id. A cleared
  #   field means the top level, i.e. the knowledge base itself; when the user may not create
  #   there it falls through to #fallback_parent, which for an edit is the stored parent — such
  #   a move could not be saved anyway — and for a create is the knowledge base either way.
  def submitted_parent
    return if !data.key?('parentId')

    parent_id = data['parentId']

    if parent_id.blank?
      return parent_relation.top_level_selectable? ? knowledge_base : nil
    end

    parent_relation.selectable_categories.find { |category| category.id == parent_id.to_i }
  end
end
