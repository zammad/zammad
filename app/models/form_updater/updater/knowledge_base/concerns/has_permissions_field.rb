# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The granular permission matrix, shared by every knowledge base form that offers it — the root
#   and the categories alike.
#
# Includers provide #permissions_parent (what the edited record inherits from: another record, or
#   nil for the root, which inherits from nothing) and may override #stored_permissions.
module FormUpdater::Updater::KnowledgeBase::Concerns::HasPermissionsField
  extend ActiveSupport::Concern

  class_methods do
    def required_permissions
      ['knowledge_base.editor']
    end
  end

  def resolve
    # Offered even when no permission exists yet: granular permissions start with the first one
    #   granted here, so gating the matrix on them would leave no way to grant it (the legacy
    #   dialog offers it unconditionally too). An untouched matrix stays a no-op — see
    #   Service::KnowledgeBase::Concerns::AppliesPermissions.
    result['permissions'] = permissions_field

    super
  end

  private

  # The field splits the rows from the selection: `permissionRows` is the prop it renders a row
  #   per role from, and off which it locks the levels that role may not be given, while its
  #   value is only which access is picked per role.
  #
  # `access` is deliberately not part of a row — it is the selection, and the field reads that
  #   from its value. Sending it twice would only invite the two to disagree.
  #
  # On the first run that selection is the form's initial value. Afterwards it is a correction of
  #   what the user has in front of them — a clamped access has to be applied to the mounted
  #   field, and only `value` does that (`initialValue` merely moves the dirty baseline; see
  #   Form.vue's `pendingValueUpdate`).
  #
  # Role ids go out as strings: the value is a JSON object keyed by them, and object keys are
  #   strings either way, so a numeric `roleId` beside a string key would only invite mismatches.
  def permissions_field
    rows = Service::KnowledgeBase::RolePermissions.execute(
      parent:              permissions_parent,
      current_permissions: selected_permissions,
    )

    field = {
      # No role that can hold knowledge base access means no matrix to render, only an empty table.
      show:           rows.any?,
      permissionRows: rows.map { |row| row.except(:access).merge(roleId: row[:roleId].to_s) },
    }

    accesses = rows.to_h { |row| [row[:roleId].to_s, row[:access]] }

    field[meta[:initial] ? :initialValue : :value] = accesses

    field
  end

  # Access levels currently selected per role, keyed by role id. Once the form is live these come
  #   back with the payload in exactly that shape; before that there is only what the record
  #   already stores (nothing, when adding). RolePermissions normalizes the keys, so the strings
  #   the form sends need no conversion here.
  def selected_permissions
    selected = data['permissions']

    return stored_permissions if !selected.is_a?(Hash) || selected.blank?

    selected
  end

  # Nothing stored: an includer editing an existing record reads them off it instead.
  def stored_permissions
    {}
  end
end
