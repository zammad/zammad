# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Form updater for editing the knowledge base root.
class FormUpdater::Updater::KnowledgeBase::Edit < FormUpdater::Updater
  include FormUpdater::Updater::KnowledgeBase::Concerns::HasPermissionsField

  def object_type
    ::KnowledgeBase
  end

  def authorized?
    return false if !current_user.permissions?(self.class.required_permissions)
    return false if id.blank?

    # Editing the root needs root editor access; the default :show? load would also pass for
    #   readers when granular permissions narrow a global editor on this knowledge base.
    @object = Gql::ZammadSchema.authorized_object_from_id(id, type: object_type, user: current_user, query: :update?)

    true
  end

  private

  # The root inherits from nothing. Passing the knowledge base itself would make stored root
  #   permissions look inherited and lock editor-capable rows to editor-only.
  def permissions_parent
    nil
  end

  def stored_permissions
    object.permissions.to_h { |permission| [permission.role_id, permission.access] }
  end
end
