// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import { camelize } from '@shared/utils/formatter'
import FieldResolver from '../FieldResolver'

export class FieldResolverAutocompletionCustomerOrganization extends FieldResolver {
  fieldType = 'organization' // TODO ...

  // TODO:
  // eslint-disable-next-line class-methods-use-this
  public fieldTypeAttributes() {
    return {
      props: {
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
