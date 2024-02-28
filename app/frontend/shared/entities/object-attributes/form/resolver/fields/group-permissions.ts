// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useAppName } from '#shared/composables/useAppName.ts'
import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import FieldResolver from '../FieldResolver.ts'

export class FieldResolverUserGroupPermissions extends FieldResolver {
  // NB: The group permissions field is currently supported only in desktop app.
  fieldType = useAppName() === 'desktop' ? 'groupPermissions' : 'hidden'

  public fieldTypeAttributes() {
    return {}
  }
}

export default <FieldResolverModule>{
  type: 'group_permissions',
  resolver: FieldResolverUserGroupPermissions,
}
