// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable zammad/zammad-detect-translatable-string */

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import FieldResolver from '../FieldResolver.ts'

export class FieldResolverUserPermissions extends FieldResolver {
  fieldType = 'toggleList'

  public fieldTypeAttributes() {
    return {}
  }
}

export default <FieldResolverModule>{
  type: 'user_permission',
  resolver: FieldResolverUserPermissions,
}
