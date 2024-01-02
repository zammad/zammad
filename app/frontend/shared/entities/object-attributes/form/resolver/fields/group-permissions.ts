// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import FieldResolver from '../FieldResolver.ts'

export class FieldResolverUserGroupPermissions extends FieldResolver {
  fieldType = 'hidden' // TODO

  // TODO:
  // eslint-disable-next-line class-methods-use-this
  public fieldTypeAttributes() {
    return {
      props: {},
    }
  }
}

export default <FieldResolverModule>{
  type: 'group_permissions',
  resolver: FieldResolverUserGroupPermissions,
}
