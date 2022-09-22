// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverAutocompletionCustomer extends FieldResolver {
  fieldType = 'customer'

  // TODO:
  // eslint-disable-next-line class-methods-use-this
  public fieldTypeAttributes() {
    return {
      props: {},
    }
  }
}

export default <FieldResolverModule>{
  type: 'user_autocompletion',
  resolver: FieldResolverAutocompletionCustomer,
}
