// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverInput extends FieldResolver {
  fieldType = () => {
    switch (this.attributeConfig.type) {
      case 'password':
        return 'password'
      case 'tel':
        return 'tel'
      case 'email':
        return 'email'
      // TODO: what about the 'url' field type?
      // case 'url'
      default:
        return 'text'
    }
  }

  public fieldTypeAttributes() {
    return {
      props: {
        maxlength: this.attributeConfig.maxlength,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'input',
  resolver: FieldResolverInput,
}
