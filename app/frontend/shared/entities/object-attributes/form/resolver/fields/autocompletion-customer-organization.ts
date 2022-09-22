// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverAutocompletionCustomerOrganization extends FieldResolver {
  fieldType = 'organization' // TODO ...

  // TODO:
  // eslint-disable-next-line class-methods-use-this
  public fieldTypeAttributes() {
    return {
      props: {},
    }
  }
}

export default <FieldResolverModule>{
  type: 'autocompletion_ajax_customer_organization',
  resolver: FieldResolverAutocompletionCustomerOrganization,
}
