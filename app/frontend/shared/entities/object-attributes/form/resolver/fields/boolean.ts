// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverBoolean extends FieldResolver {
  // TODO: at the moment we need to use the select field, because the checkbox variant switch can not be used
  // out of the box without sideeffects and correct core workflow support.
  // We need to build a new "toggle" field which support all needed stuff.
  fieldType = 'select'

  public fieldTypeAttributes() {
    const options = this.attributeConfig.options as Record<string, string>

    return {
      props: {
        options: [
          {
            label: options.true,
            value: true,
          },
          {
            label: options.false,
            value: false,
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
