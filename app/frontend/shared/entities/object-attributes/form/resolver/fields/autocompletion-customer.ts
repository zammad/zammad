// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import { camelize } from '@shared/utils/formatter'
import FieldResolver from '../FieldResolver'

export class FieldResolverAutocompletionCustomer extends FieldResolver {
  fieldType = 'customer'

  public fieldTypeAttributes() {
    return {
      props: {
        noOptionsLabelTranslation: !this.attributeConfig.translate,
        belongsToObjectField: camelize(
          (this.attributeConfig.belongs_to as string) || '',
        ),
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'user_autocompletion',
  resolver: FieldResolverAutocompletionCustomer,
}
