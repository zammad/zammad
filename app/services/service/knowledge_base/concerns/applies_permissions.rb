# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Applies the granular role permissions that ride inside the input of a knowledge base write
#   service, in the same transaction as the write itself. Shared by the knowledge base and its
#   categories, which carry permissions in exactly the same shape.
#
# KnowledgeBase::PermissionsUpdate is the one write path for permissions (the legacy permissions
#   dialog goes through it too, via KnowledgeBase::PermissionsController): it refuses to override an
#   unoverrideable parent permission, cascades the cleanup to the whole subtree, and — this is why
#   `current_user` has to be handed over — refuses a change that would take the editing user's own
#   editor access away.
#
# Order is load-bearing on both sides. The object has to be saved before this runs (the permissions
#   are rows pointing at it, and the lock-yourself-out check reads effective access back from the
#   database), and when a category is moved it has to run *after* the new parent is in place, since
#   what may be granted at all is derived from the parent's effective permissions.
module Service::KnowledgeBase::Concerns::AppliesPermissions
  extend ActiveSupport::Concern

  private

  # @param object [KnowledgeBase, KnowledgeBase::Category] the saved object the permissions belong to
  # @param permissions [Array<Hash>, nil] `{ role:, access: }` rows. Nil leaves the stored
  #   permissions untouched — a client that does not offer the matrix at all sends nothing — while
  #   an empty list drops the object's own permissions, so it inherits everything.
  def apply_permissions(object, permissions)
    return if permissions.nil?
    return if pointless_first_permissions?(permissions)

    ::KnowledgeBase::PermissionsUpdate
      .new(object, current_user)
      .update!(**permissions.to_h { |row| [row[:role], row[:access]] })
  rescue Exceptions::UnprocessableContent => e
    # Whatever PermissionsUpdate refuses — a role locking the editing user out, an inherited access
    #   that may not be overridden — is about the submitted matrix and nothing else, so it is named
    #   as such. Without an attribute the message would end up on the form rather than below the
    #   matrix the user has to correct.
    raise Exceptions::InvalidAttribute.new('permissions', e.message)
  end

  # The form offers the matrix before any permission exists, because that is the only way to grant
  #   the first one. Saving a form must therefore not be what switches the whole instance to
  #   granular permissions (KnowledgeBase.granular_permissions? is "any permission row exists", and
  #   it changes how content is scoped everywhere): as long as none exist, a selection that only
  #   restates what every role has anyway is nothing to store.
  #
  #   Once they do exist, this cannot get in the way — PermissionsUpdate then cleans up rows that
  #   restate what is inherited by itself.
  def pointless_first_permissions?(permissions)
    return false if ::KnowledgeBase.granular_permissions?

    permissions.all? do |row|
      row[:access] == ::KnowledgeBase::EffectivePermission.default_role_access(row[:role])
    end
  end
end
