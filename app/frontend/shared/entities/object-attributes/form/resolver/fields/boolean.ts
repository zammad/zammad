// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverBoolean extends FieldResolver {
  fieldType = 'select'

  public fieldTypeAttributes() {
    const options = this.attributeConfig.options as Record<string, string>

    return {
      props: {
        options: [
          {
            label: options.false,
            value: false,
          },
          {
            label: options.true,
            value: true,
          },
        ],
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'boolean',
  resolver: FieldResolverBoolean,
}
