// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import { getTimestampWithDiff } from '#shared/utils/datetime.ts'

import { FieldResolver } from '../FieldResolver.ts'

export class FieldResolverDateTime extends FieldResolver {
  fieldType = 'datetime'

  public fieldTypeAttributes() {
    const value = this.attributeConfig.diff
      ? getTimestampWithDiff(this.attributeConfig.diff as number)
      : undefined

    return {
      value,
      props: {
        clearable: !!this.attributeConfig.null,
        pastOnly: !this.attributeConfig.future,
        futureOnly: !this.attributeConfig.past,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'datetime',
  resolver: FieldResolverDateTime,
}
