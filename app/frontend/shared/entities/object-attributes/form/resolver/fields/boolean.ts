// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import FieldResolver from '../FieldResolver.ts'

export class FieldResolverBoolean extends FieldResolver {
  fieldType = 'toggle'

  public fieldTypeAttributes() {
    const variants = this.attributeConfig.options as Record<string, string>

    return {
      value: false, // if it has default, it will be overriden after
      props: {
        variants,
      },
      // Add top margin only in multi-column mode, so the field aligns nicely with other which have visible labels.
      //   More info in `app/frontend/apps/desktop/styles/main.css:77`.
      wrapperClass: '@lg/form-group:mt-6',
    }
  }
}

export default <FieldResolverModule>{
  type: 'boolean',
  resolver: FieldResolverBoolean,
}
