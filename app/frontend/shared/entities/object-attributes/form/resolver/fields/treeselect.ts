// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TreeSelectOption } from '@shared/components/Form/fields/FieldTreeSelect/types'
import type { FormFieldAdditionalProps } from '@shared/components/Form/types'
import type {
  FieldResolverModule,
  ObjectAttributeTreeSelectOption,
} from '@shared/entities/object-attributes/types/resolver'
import FieldResolver from '../FieldResolver'

export class FieldResolverTreeselect extends FieldResolver {
  fieldType = 'treeselect'

  public fieldTypeAttributes() {
    const props: FormFieldAdditionalProps = {
      noOptionsLabelTranslation: !this.attributeConfig.translate,
      clearable: this.attributeConfig.nulloption || false,
    }

    if (this.attributeConfig.options) {
      props.options = this.mappedOptions()
    }

    if (this.attributeType === 'multi_tree_select') props.multiple = true

    return {
      props,
    }
  }

  private mappedOptions(): TreeSelectOption[] {
    const mapTreeSelectOptions = (
      options: ObjectAttributeTreeSelectOption[],
    ) => {
      return options.reduce(
        (treeSelectOptions: TreeSelectOption[], { children, name, value }) => {
          const treeSelectOption: TreeSelectOption = {
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
