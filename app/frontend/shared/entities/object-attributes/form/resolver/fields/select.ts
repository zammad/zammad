// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldAdditionalProps, FormSchemaField } from '#shared/components/Form/types.ts'
import type {
  FieldResolverModule,
  ObjectAttributeSelectOptions,
} from '#shared/entities/object-attributes/types/resolver.ts'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { camelize } from '#shared/utils/formatter.ts'

import { FieldResolver } from '../FieldResolver.ts'

import type { Dictionary } from 'ts-essentials'

export type ObjectSelectValue = string | number | boolean

export interface ObjectSelectOption {
  label?: string
  disabled?: boolean
  value: ObjectSelectValue
}

export type OptionValueLookup = Dictionary<ObjectSelectOption>
export type SelectValueWithoutBoolean = Exclude<ObjectSelectValue, boolean>

export class FieldResolverSelect extends FieldResolver {
  fieldType = 'select'

  protected multiFieldAttributeType = 'multiselect'

  // True when the attribute carries its own ordered option list — i.e. the
  // options are a static array and there's no relation overriding them.
  // Object-keyed options (no stable iteration order) and relation-resolved
  // options (server-driven) lack a given order; for those, callers fall
  // back to label sorting.
  protected staticOptionsOrder: boolean

  constructor(object: EnumObjectManagerObjects, objectAttribute: ObjectAttribute) {
    super(object, objectAttribute)

    const { relation, options } = this.attributeConfig

    this.staticOptionsOrder = !relation && Array.isArray(options)
  }

  public fieldTypeAttributes() {
    const attributes: Partial<FormSchemaField> = {}
    const props: FormFieldAdditionalProps = {
      noOptionsLabelTranslation: !this.attributeConfig.translate,
      clearable: !!this.attributeConfig.nulloption,
      options: [],
      historicalOptions: this.attributeConfig.historical_options,
    }

    // Standard-form usage reads the raw relation type directly — distinct
    // from the advanced-filter signals on the FilterAttribute, which split
    // into form-updater vs autocomplete branches.
    if (this.attributeConfig.relation) {
      attributes.relation = { type: this.attributeConfig.relation as string }

      if (this.attributeConfig.filter) {
        attributes.relation.filterIds = this.attributeConfig.filter as number[]
      }

      props.belongsToObjectField = camelize((this.attributeConfig.belongs_to as string) || '')
    } else if (this.attributeConfig.options) {
      props.options = this.mappedOptions()
    }

    if (!this.staticOptionsOrder) props.sorting = 'label'

    if (this.attributeType === this.multiFieldAttributeType) props.multiple = true

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

  public override getFieldFilterOperators() {
    return ['is']
  }

  public override getFilterOperatorProps() {
    // Autocomplete-routed attributes (e.g. owner_id) render a FieldCustomer/
    // Agent/Organization row whose props come from `is.ts` only — none of the
    // select-flavoured props below apply, so emit nothing for them.
    if (this.filterAutocompleteType) return

    // Static options come from attribute config; relation-typed attributes
    // get their options from the form updater instead, so we omit the key
    // here entirely rather than emitting an empty array.
    const props: Record<string, unknown> = {
      noOptionsLabelTranslation: !this.attributeConfig.translate,
      historicalOptions: this.attributeConfig.historical_options,
    }

    if (!this.staticOptionsOrder) props.sorting = 'label'
    if (!this.attributeConfig.relation && this.attributeConfig.options) {
      props.options = this.mappedOptions()
    }

    return { is: props }
  }

  public override getFilterRelation() {
    const relation = this.attributeConfig.relation as string | undefined
    if (!relation) return
    // Autocomplete-style relations are surfaced via getFilterAutocompleteType
    // — they don't go through the form-updater option-resolution path.
    if (this.filterAutocompleteType) return
    return relation
  }
}

export default <FieldResolverModule>{
  type: 'select',
  resolver: FieldResolverSelect,
}
