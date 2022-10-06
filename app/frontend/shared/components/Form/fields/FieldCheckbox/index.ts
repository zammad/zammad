// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import { checkbox as checkboxDefinition } from '@formkit/inputs'
import { has } from '@formkit/utils'
import initializeFieldDefinition from '@shared/form/core/initializeFieldDefinition'
import extendSchemaDefinition from '@shared/form/utils/extendSchemaDefinition'
import { CheckboxVariant } from './types'

const addOptionCheckedDataAttribute = (node: FormKitNode) => {
  node.addProps(['variant', 'translations'])

  // TODO make design for adding translations
  // [ ] text Label (?)
  // Label    text ( )
  // extendSchemaDefinition(
  //   node,
  //   'prefix',
  //   '$translations[$value] == null ? "" : $translations[$value]',
  // )

  extendSchemaDefinition(node, 'wrapper', {
    attrs: {
      'data-is-checked': {
        if: '$options.length',
        then: {
          if: '$fns.isChecked($option.value)',
          then: 'true',
          else: undefined,
        },
        else: {
          if: '$_value',
          then: 'true',
          else: undefined,
        },
      },
    },
  })
}

const handleVariant = (node: FormKitNode) => {
  const { props } = node

  const setVariantClasses = (variant: CheckboxVariant) => {
    if (CheckboxVariant.Switch === variant) {
      props.wrapperClass = 'flex-row-reverse h-14 px-2'
      props.innerClass =
        'bg-gray-300 relative inline-flex flex-shrink-0 h-6 w-10 border border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200 focus:outline-none focus-within:ring-1 focus-within:ring-white focus-within:ring-opacity-75 formkit-is-checked:bg-blue formkit-invalid:border-red formkit-invalid:border-solid'
      props.decoratorClass =
        'translate-x-0 pointer-events-none inline-block h-[22px] w-[22px] rounded-full bg-white shadow-lg transform ring-0 transition ease-in-out duration-200 peer-checked:translate-x-4'
      props.outerClass = 'px-2'
      props.inputClass = '$reset peer sr-only'
    } else {
      props.wrapperClass = 'ltr:pl-2 rtl:pr-2'
      props.inputClass =
        'h-4 w-4 border-[1.5px] border-white rounded-sm bg-transparent focus:border-blue focus:bg-blue-highlight checked:focus:color-blue checked:bg-blue checked:border-blue checked:focus:bg-blue checked:hover:bg-blue'
    }
  }

  node.on('created', () => {
    if (!has(props, 'variant')) {
      props.variant = CheckboxVariant.Default
    }

    setVariantClasses(props.variant)

    node.on('prop:variant', ({ payload }) => {
      setVariantClasses(payload)
    })
  })
}

initializeFieldDefinition(checkboxDefinition, {
  features: [addOptionCheckedDataAttribute, handleVariant],
})

export default {
  fieldType: 'checkbox',
  definition: checkboxDefinition,
}

export { CheckboxVariant }
