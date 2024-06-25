// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import { camelize } from '#shared/utils/formatter.ts'

import FieldResolver from '../FieldResolver.ts'

export class FieldResolverAutocompletionCustomerOrganization extends FieldResolver {
  fieldType = 'organization'

  public fieldTypeAttributes() {
    return {
      props: {
        clearable: this.attributeConfig.nulloption ?? true,
        noOptionsLabelTranslation: !this.attributeConfig.translate,
        belongsToObjectField: camelize(
          (this.attributeConfig.belongs_to as string) || '',
        ),
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'autocompletion_ajax_customer_organization',
  resolver: FieldResolverAutocompletionCustomerOrganization,
}
