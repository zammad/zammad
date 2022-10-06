// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { CheckboxVariant } from '@shared/components/Form/fields/FieldCheckbox'
import type { FieldResolverModule } from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverBoolean extends FieldResolver {
  fieldType = 'checkbox'

  public fieldTypeAttributes() {
    const options = this.attributeConfig.options as Record<string, string>

    return {
      props: {
        variant: CheckboxVariant.Switch,
        translations: options,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'boolean',
  resolver: FieldResolverBoolean,
}
