// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { SelectOption } from '@shared/components/Form/fields/FieldSelect'
import type {
  FormFieldAdditionalProps,
  FormSchemaField,
} from '@shared/components/Form/types'
import type {
  FieldResolverModule,
  ObjectAttributeSelectOptions,
} from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverSelect extends FieldResolver {
  fieldType = 'select'

  public fieldTypeAttributes() {
    const attributes: Partial<FormSchemaField> = {}
    const props: FormFieldAdditionalProps = {
      noOptionsLabelTranslation: !this.attributeConfig.translate,
      options: [],
    }

    if (this.attributeConfig.options) {
      props.options = this.mappedOptions()
    } else if (this.attributeConfig.relation) {
      attributes.relation = this.attributeConfig.relation as string
    }

    if (this.attributeType === 'multiselect') props.multiple = true

    return {
      ...attributes,
      props,
    }
  }

  private mappedOptions(): SelectOption[] {
    const options = this.attributeConfig.options as ObjectAttributeSelectOptions

    if (Array.isArray(options)) {
      return options.map(({ name, value }) => ({
        label: name,
        value,
      }))
    }

    return Object.keys(options).map((key) => ({
      label: key,
      value: options[key],
    }))
  }
}

export default <FieldResolverModule>{
  type: 'select',
  resolver: FieldResolverSelect,
}
