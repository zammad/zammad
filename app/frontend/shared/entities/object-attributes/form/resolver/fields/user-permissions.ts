// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable zammad/zammad-detect-translatable-string */

import { useAppName } from '#shared/composables/useAppName.ts'
import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import FieldResolver from '../FieldResolver.ts'

export class FieldResolverUserPermissions extends FieldResolver {
  // NB: The user permissions field is currently supported only in desktop app.
  fieldType = useAppName() === 'desktop' ? 'toggleList' : 'hidden'

  public fieldTypeAttributes() {
    return {}
  }
}

export default <FieldResolverModule>{
  type: 'user_permission',
  resolver: FieldResolverUserPermissions,
}
