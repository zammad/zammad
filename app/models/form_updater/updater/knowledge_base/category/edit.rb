# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Form updater for editing an existing knowledge base category.
class FormUpdater::Updater::KnowledgeBase::Category::Edit < FormUpdater::Updater
  include FormUpdater::Updater::KnowledgeBase::Category::Concerns::HasParentAndPermissions

  def authorized?
    return false if !current_user.permissions?(self.class.required_permissions)
    return false if id.blank?

    # Not the base class's default :show? load — that passes for readers too. Editing needs
    #   #update? (editor access), so a granular reader of this category is rejected even though
    #   the global permission above is satisfied.
    @object = Gql::ZammadSchema.authorized_object_from_id(id, type: object_type, user: current_user, query: :update?)

    true
  end

  private

  # The edited category stays in its own knowledge base, which is not necessarily the active one.
  def knowledge_base
    @knowledge_base ||= object.knowledge_base
  end

  def excluded_category
    object
  end

  # Nil for a top level category, which the form renders as an empty field — the same thing
  #   clearing it means.
  #
  # The stored parent may legally be missing from the options (e.g. a granular editor whose
  #   parent category is reader-only for them) — the form has to render that as-is, and keeping
  #   the parent unchanged must stay possible on submit.
  def initial_parent_value
    object.parent_id
  end

  def fallback_parent
    object.parent || knowledge_base
  end

  def stored_permissions
    object.permissions.to_h { |permission| [permission.role_id, permission.access] }
  end
end
