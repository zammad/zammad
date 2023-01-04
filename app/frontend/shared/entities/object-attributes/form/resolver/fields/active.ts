// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverActive extends FieldResolver {
  fieldType = 'toggle'

  // eslint-disable-next-line class-methods-use-this
  public fieldTypeAttributes() {
    return {
      props: {
        variants: {
          true: __('yes'),
          false: __('no'),
        },
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'active',
  resolver: FieldResolverActive,
}
