// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type {
  GroupAccess,
  GroupPermissionReactive,
} from '#shared/components/Form/fields/FieldGroupPermissions/types.ts'
import type { FormFieldValue } from '#shared/components/Form/types.ts'
import { useAppName } from '#shared/composables/useAppName.ts'
import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolver } from '../FieldResolver.ts'

export class FieldResolverUserGroupPermissions extends FieldResolver {
  // NB: The group permissions field is currently supported only in desktop app.
  fieldType = useAppName() === 'desktop' ? 'groupPermissions' : 'hidden'

  public fieldTypeAttributes() {
    return {}
  }

  public transformFieldValue(value: FormFieldValue): FormFieldValue {
    return (value as unknown as GroupPermissionReactive[])?.reduce(
      (groupPermissions, row) => {
        if (!row.groups) return groupPermissions

        groupPermissions.push(
          ...(row.groups as unknown as SelectValue[]).map((groupInternalId) => ({
            groupInternalId,
            accessType: Object.keys(row.groupAccess).reduce((accesses, key) => {
              if (row.groupAccess[key as GroupAccess]) accesses.push(key as GroupAccess)
              return accesses
            }, [] as GroupAccess[]),
          })),
        )
        return groupPermissions
      },
      [] as {
        groupInternalId: SelectValue
        accessType: GroupAccess[]
      }[],
    )
  }
}

export default <FieldResolverModule>{
  type: 'group_permissions',
  resolver: FieldResolverUserGroupPermissions,
}
