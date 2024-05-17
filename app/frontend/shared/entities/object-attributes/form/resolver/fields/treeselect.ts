// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  FieldResolverModule,
  ObjectAttributeTreeSelectOption,
} from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolverSelect } from './select.ts'

export interface ObjectTreeSelectOption {
  label?: string
  value: string
  children?: ObjectTreeSelectOption[]
}

export class FieldResolverTreeselect extends FieldResolverSelect {
  fieldType = 'treeselect'

  multiFieldAttributeType = 'multi_tree_select'

  mappedOptions(): ObjectTreeSelectOption[] {
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
