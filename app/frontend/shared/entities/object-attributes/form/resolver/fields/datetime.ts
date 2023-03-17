// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverDateTime extends FieldResolver {
  fieldType = 'datetime'

  // TODO: there are also :diff, :future and :past attributes, what about them?
  // eslint-disable-next-line class-methods-use-this
  public fieldTypeAttributes() {
    return {
      props: {},
    }
  }
}

export default <FieldResolverModule>{
  type: 'datetime',
  resolver: FieldResolverDateTime,
}
