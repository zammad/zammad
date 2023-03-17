// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverUserPermissions extends FieldResolver {
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
  type: 'user_permission',
  resolver: FieldResolverUserPermissions,
}
