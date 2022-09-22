// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { CheckboxVariant } from '@shared/components/Form/fields/FieldCheckbox'
import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverBoolean extends FieldResolver {
  fieldType = 'checkbox'

  // eslint-disable-next-line class-methods-use-this
  public fieldTypeAttributes() {
    return {
      props: {
        variant: CheckboxVariant.Switch,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'active',
  resolver: FieldResolverBoolean,
}
