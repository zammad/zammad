// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolver } from '../FieldResolver.ts'

export class FieldResolverActive extends FieldResolver {
  fieldType = 'toggle'

  private variants() {
    return {
      true: __('yes'),
      false: __('no'),
    }
  }

  public fieldTypeAttributes() {
    return {
      props: {
        variants: this.variants(),
      },
    }
  }

  public override getFieldFilterOperators() {
    return ['is']
  }

  private filterOptions() {
    return Object.entries(this.variants()).map(([value, label]) => ({ value, label }))
  }

  public override getFilterOperatorProps() {
    return {
      is: {
        options: this.filterOptions(),
        sorting: 'label',
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'active',
  resolver: FieldResolverActive,
}
