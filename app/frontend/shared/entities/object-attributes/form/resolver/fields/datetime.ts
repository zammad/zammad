// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import FieldResolver from '../FieldResolver.ts'

export class FieldResolverDateTime extends FieldResolver {
  fieldType = 'datetime'

  // TODO: there are also :diff, :future and :past attributes, what about them?
  public fieldTypeAttributes() {
    return {
      props: {
        clearable: this.attributeConfig.null || false,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'datetime',
  resolver: FieldResolverDateTime,
}
