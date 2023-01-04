// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

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
