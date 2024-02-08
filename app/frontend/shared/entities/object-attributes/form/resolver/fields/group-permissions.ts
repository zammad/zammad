// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import FieldResolver from '../FieldResolver.ts'

export class FieldResolverUserGroupPermissions extends FieldResolver {
  fieldType = 'groupPermissions'

  public fieldTypeAttributes() {
    return {}
  }
}

export default <FieldResolverModule>{
  type: 'group_permissions',
  resolver: FieldResolverUserGroupPermissions,
}
