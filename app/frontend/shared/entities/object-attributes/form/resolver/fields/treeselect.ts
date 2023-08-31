// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldAdditionalProps } from '#shared/components/Form/types.ts'
import type {
  FieldResolverModule,
  ObjectAttributeTreeSelectOption,
} from '#shared/entities/object-attributes/types/resolver.ts'
import FieldResolver from '../FieldResolver.ts'

export interface ObjectTreeSelectOption {
  label?: string
  value: string
  children?: ObjectTreeSelectOption[]
}

export class FieldResolverTreeselect extends FieldResolver {
  fieldType = 'treeselect'

  public fieldTypeAttributes() {
    const props: FormFieldAdditionalProps = {
      noOptionsLabelTranslation: !this.attributeConfig.translate,
      clearable: this.attributeConfig.nulloption || false,
      historicalOptions: this.attributeConfig.historical_options,
    }

    if (this.attributeConfig.options) {
      props.options = this.mappedOptions()
    }

    if (this.attributeType === 'multi_tree_select') props.multiple = true

    return {
      props,
    }
  }

  private mappedOptions(): ObjectTreeSelectOption[] {
    const mapTreeSelectOptions = (
      options: ObjectAttributeTreeSelectOption[],
    ) => {
      return options.reduce(
        (
          treeSelectOptions: ObjectTreeSelectOption[],
          { children, name, value },
        ) => {
          const treeSelectOption: ObjectTreeSelectOption = {
            label: name,
            value,
          }

          if (children) {
            treeSelectOption.children = mapTreeSelectOptions(children)
          }

          treeSelectOptions.push(treeSelectOption)

          return treeSelectOptions
        },
        [],
      )
    }

    return mapTreeSelectOptions(
      this.attributeConfig
        .options as unknown as ObjectAttributeTreeSelectOption[],
    )
  }
}

export default <FieldResolverModule>{
  type: 'tree_select',
  resolver: FieldResolverTreeselect,
}
