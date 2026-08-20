# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Per-role permission rows for the knowledge base category form: which access level a role
#   currently has, what it inherits from the parent, and which levels may legally be picked.
#
# `allowedAccesses` puts the disable matrix that used to live client-side (the coffee
#   permissions dialog) on the server, derived from the two rules that already govern the write
#   path: a role can only be given a level its own global permission allows
#   (KnowledgeBase::Permission#allowed_access), and an inherited `editor`/`none` cannot be
#   overridden at all (KnowledgeBase::PermissionsUpdate#ensure_unoverrideable_permissions!).
#
# `parent` is the object the edited node inherits from: another category, or the knowledge base
#   itself for a top-level category. It is nil when the edited node is the knowledge base root,
#   which inherits from nothing. Mirrors KnowledgeBase::PermissionsUpdate#parent_object_permissions.
class Service::KnowledgeBase::RolePermissions < Service::Base
  attr_reader :parent, :current_permissions

  # @param parent [KnowledgeBase::Category, KnowledgeBase, nil] object the edited node inherits from
  # @param current_permissions [Hash{Integer,String => String}] role id => currently selected
  #   access, i.e. the category's own stored permissions or the values the form sends back
  def initialize(parent: nil, current_permissions: {})
    @parent = parent
    @current_permissions = current_permissions.transform_keys(&:to_i)
  end

  def execute
    capable_roles.map { |role| row_for(role) }
  end

  private

  # Only roles that can hold *some* knowledge base access get a row, mirroring the legacy
  #   dialog's roles_editor + roles_reader lists. A role with neither permission could not be
  #   given any level, so it would only render as an inert row.
  def capable_roles
    (editor_roles + reader_roles).sort_by(&:id)
  end

  def editor_roles
    @editor_roles ||= ::Role.with_permissions('knowledge_base.editor').to_a
  end

  # Reader-only: roles that are editor-capable are covered by #editor_roles already.
  def reader_roles
    @reader_roles ||= ::Role.with_permissions('knowledge_base.reader').to_a - editor_roles
  end

  def editor_role_ids
    @editor_role_ids ||= editor_roles.to_set(&:id)
  end

  def row_for(role)
    inherited = inherited_access(role)
    allowed   = allowed_accesses(role, inherited)

    {
      roleId:          role.id,
      roleName:        role.name,
      access:          resolved_access(role, inherited, allowed),
      inheritedAccess: inherited,
      allowedAccesses: allowed,
    }
  end

  def parent_permissions
    @parent_permissions ||= parent&.permissions_effective || []
  end

  def inherited_access(role)
    parent_permissions.find { |permission| permission.role_id == role.id }&.access
  end

  def allowed_accesses(role, inherited)
    case inherited
    when 'editor'
      # Limiting a role that is already an editor above would have no effect.
      %w[editor]
    when 'none'
      # The parent is not visible for this role, so nothing below it can be.
      %w[none]
    else
      # Inherited 'reader' is overridable, and without an inherited level nothing constrains us.
      base_accesses(role)
    end
  end

  def base_accesses(role)
    editor_role_ids.include?(role.id) ? %w[editor reader none] : %w[reader none]
  end

  # The level the form should show as selected. An untouched row falls back to what it inherits,
  #   matching the legacy dialog, which rendered permissions_effective rather than only the
  #   category's own permissions.
  #
  #   With nothing inherited either, it falls back to the level the role holds by virtue of its own
  #   permission — `allowed.first` is 'editor' for an editor-capable role and 'reader' otherwise,
  #   the same default as KnowledgeBase::EffectivePermission#default_role_access. That is the
  #   access such a role genuinely has today, and defaulting to 'none' instead would both misreport
  #   it and, once saved, strip every role's access — including the editing user's, which
  #   KnowledgeBase::PermissionsUpdate#ensure_editable! rejects outright.
  #
  #   A selection that is no longer allowed — the parent changed and narrowed the options under
  #   it — is clamped to the most restrictive remaining level instead of being kept illegal.
  #   Never widening on an automatic re-resolve keeps a parent change from silently granting
  #   access nobody asked for.
  def resolved_access(role, inherited, allowed)
    selected = current_permissions[role.id] || inherited || allowed.first

    return selected if allowed.include?(selected)

    allowed.last
  end
end
