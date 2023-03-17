// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverBoolean extends FieldResolver {
  fieldType = 'toggle'

  public fieldTypeAttributes() {
    const variants = this.attributeConfig.options as Record<string, string>

    return {
      value: false, // if it has default, it will be overriden after
      props: {
        variants,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'boolean',
  resolver: FieldResolverBoolean,
}
