// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormFieldAdditionalProps,
  FormSchemaField,
} from '#shared/components/Form/types.ts'
import type {
  FieldResolverModule,
  ObjectAttributeSelectOptions,
} from '#shared/entities/object-attributes/types/resolver.ts'
import { camelize } from '#shared/utils/formatter.ts'

import FieldResolver from '../FieldResolver.ts'

export type ObjectSelectValue = string | number | boolean

export interface ObjectSelectOption {
  label?: string
  disabled?: boolean
  value: ObjectSelectValue
}

export class FieldResolverSelect extends FieldResolver {
  fieldType = 'select'

  protected multiFieldAttributeType = 'multiselect'

  public fieldTypeAttributes() {
    const attributes: Partial<FormSchemaField> = {}
    const props: FormFieldAdditionalProps = {
      noOptionsLabelTranslation: !this.attributeConfig.translate,
      clearable: this.attributeConfig.nulloption || false,
      options: [],
      historicalOptions: this.attributeConfig.historical_options,
    }

    if (this.attributeConfig.relation) {
      attributes.relation = {
        type: this.attributeConfig.relation as string,
      }

      if (this.attributeConfig.filter) {
        attributes.relation.filterIds = this.attributeConfig.filter as number[]
      }

      props.belongsToObjectField = camelize(
        (this.attributeConfig.belongs_to as string) || '',
      )

      props.sorting = 'label'
    } else if (this.attributeConfig.options) {
      props.options = this.mappedOptions()
    }

    if (this.attributeType === this.multiFieldAttributeType)
      props.multiple = true

    return {
      ...attributes,
      props,
    }
  }

  protected mappedOptions(): ObjectSelectOption[] {
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
