// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolver } from '../FieldResolver.ts'

export class FieldResolverInteger extends FieldResolver {
  fieldType = 'number'

  public fieldTypeAttributes() {
    return {
      props: {
        min: this.attributeConfig.min,
        max: this.attributeConfig.max,
        // Coerce the stored value to an integer (FormKit `number` input).
        number: 'integer',
      },
    }
  }

  public override getFieldFilterOperators() {
    // A single `in range` operator (two number inputs for min / max) covers
    // the >= / <= / = scenarios via blank-able bounds, matching the backend
    // selector operator of the same name.
    return ['in range']
  }
}

export default <FieldResolverModule>{
  type: 'integer',
  resolver: FieldResolverInteger,
}
