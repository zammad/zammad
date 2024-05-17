// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import FieldResolver from '../FieldResolver.ts'

export class FieldResolverTextarea extends FieldResolver {
  fieldType = 'textarea'

  public fieldTypeAttributes() {
    return {
      props: {
        maxlength: this.attributeConfig.maxlength,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'textarea',
  resolver: FieldResolverTextarea,
}
