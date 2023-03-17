// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RequiredPermission } from '@shared/types/permission'

/**
 * Check if the access can be granted for the given permissions.
 *
 * Examples:
 * hasPermission('ticket.agent', [...]) # access to certain permission key
 * hasPermission['ticket.agent', 'ticket.customer'], [...]) # access to one of permission keys
 *
 * hasPermission('user_preferences.calendar+ticket.agent', [...]) # access must have two permission keys
 *
 * hasPermission('admin.*', [...]) # access if one sub key access exists
 *
 * @param {Array<string>|string} requiredPermission - The permissions which are required.
 * @param {Array<string>} permissions - The available permission.
 *
 * @returns {boolean}
 */
const hasPermission = (
  requiredPermission: RequiredPermission,
  permissions: Array<string>,
  // eslint-disable-next-line sonarjs/cognitive-complexity
): boolean => {
  const requiredPermissions = Array.isArray(requiredPermission)
    ? requiredPermission
    : [requiredPermission]

  // Available with any permission.
  if (requiredPermissions.length === 0 || requiredPermissions.includes('*')) {
    return true
  }

  // If a permission is needed, but no permission was given, permission will not be granted.
  if (permissions.length === 0) return false

  for (const localRequirePermission of requiredPermissions) {
    // The permission can be combined with a 'AND', then every single permission needs to match.
    const localRequiredPermissions = localRequirePermission.split('+')

    let accessGranted = false
    for (const requiredPermissionItem of localRequiredPermissions) {
      let singleAccessGranted = false

      // Check first if a permission with wildcard is matching.
      if (requiredPermissionItem.includes('*')) {
        const regexRequiredPermission = new RegExp(
          requiredPermissionItem.replace('.', '\\.').replace('*', '.+'),
        )

        singleAccessGranted = permissions.some((permission) =>
          regexRequiredPermission.test(permission),
        )
      }

      // If not already a wildcard permission match exists, check for a direct permission.
      if (!singleAccessGranted) {
        const partsRequiredPermission = requiredPermissionItem.split('.')

        let checkPartsRequiredPermission = ''
        for (const partRequiredPermission of partsRequiredPermission) {
          if (checkPartsRequiredPermission) checkPartsRequiredPermission += '.'
          checkPartsRequiredPermission += partRequiredPermission

          singleAccessGranted = permissions.includes(
            checkPartsRequiredPermission,
          )

          if (singleAccessGranted) break
        }
      }

      accessGranted = singleAccessGranted

      // If one permission not exists, no access can be granted for this required permission.
      if (!accessGranted) break
    }

    // If one required permission matches, the access can be granted.
    if (accessGranted) return accessGranted
  }

  return false
}

export default hasPermission
