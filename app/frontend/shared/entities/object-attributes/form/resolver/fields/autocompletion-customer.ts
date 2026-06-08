// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import { camelize } from '#shared/utils/formatter.ts'

import { FieldResolver } from '../FieldResolver.ts'

export class FieldResolverAutocompletionCustomer extends FieldResolver {
  fieldType = 'customer'

  public fieldTypeAttributes() {
    return {
      props: {
        clearable: this.attributeConfig.nulloption ?? true,
        noOptionsLabelTranslation: !this.attributeConfig.translate,
        belongsToObjectField: camelize((this.attributeConfig.belongs_to as string) || ''),
      },
    }
  }

  public override getFieldFilterOperators() {
    return ['is']
  }

  // Emit the relation so restored filter values are coerced to integer IDs
  // (the autocomplete options match by numeric ID).
  public override getFilterRelation() {
    return this.attributeConfig.relation as string
  }
}

export default <FieldResolverModule>{
  type: 'user_autocompletion',
  resolver: FieldResolverAutocompletionCustomer,
}
