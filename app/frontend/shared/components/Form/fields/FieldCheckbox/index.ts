// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { checkbox as checkboxDefinition } from '@formkit/inputs'
import { has } from '@formkit/utils'

import { useAppName } from '#shared/composables/useAppName.ts'
import initializeFieldDefinition from '#shared/form/core/initializeFieldDefinition.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import extendSchemaDefinition from '#shared/form/utils/extendSchemaDefinition.ts'

import type { FormKitNode } from '@formkit/core'

const addCheckedDataAttribute = (node: FormKitNode) => {
  extendSchemaDefinition(node, 'wrapper', {
    attrs: {
      'data-is-checked': {
        if: '$value',
        then: 'true',
        else: undefined,
      },
      'data-test-id': 'checkbox-label',
    },
  })
}

const handleAlternativeBorder = (node: FormKitNode) => {
  // The alternative border color below is specific to desktop field design only.
  if (useAppName() !== 'desktop') return

  const { props } = node

  node.addProps(['alternativeBorder'])

  const setClasses = (alternativeBorder: boolean) => {
    if (alternativeBorder) {
      props.decoratorClass =
        'border-stone-200 dark:border-neutral-500 text-stone-200 dark:text-neutral-500 formkit-checked:border-gray-300 dark:formkit-checked:border-neutral-400 formkit-checked:text-gray-300 dark:formkit-checked:text-neutral-400'
    } else {
      props.decoratorClass =
        'border-stone-200 dark:border-neutral-500 text-stone-200 dark:text-neutral-500 formkit-checked:border-gray-100 dark:formkit-checked:border-neutral-400 formkit-checked:text-gray-100 dark:formkit-checked:text-neutral-400'
    }
  }

  node.on('created', () => {
    if (!has(props, 'alternativeBorder')) props.alternativeBorder = false

    setClasses(props.alternativeBorder)

    node.on('prop:alternativeBorder', ({ payload }) => {
      setClasses(payload)
    })
  })
}

initializeFieldDefinition(checkboxDefinition, {
  props: ['alternativeBorder'],
  features: [
    addCheckedDataAttribute,
    handleAlternativeBorder,
    formUpdaterTrigger(),
  ],
})

export default {
  fieldType: 'checkbox',
  definition: checkboxDefinition,
}
