// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import { radio as radioDefinition } from '@formkit/inputs'
import { has } from '@formkit/utils'
import initializeFieldDefinition from '@shared/form/core/initializeFieldDefinition'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'
import extendSchemaDefinition from '@shared/form/utils/extendSchemaDefinition'

// TODO: Add story, when storybook replacement (histoire) was merged.

const addOptionCheckedDataAttribute = (node: FormKitNode) => {
  extendSchemaDefinition(node, 'wrapper', {
    attrs: {
      'data-is-checked': {
        if: '$fns.isChecked($option.value)',
        then: 'true',
        else: undefined,
      },
    },
  })
}

const addSubmitEvent = (node: FormKitNode) => {
  if (typeof node.props.onSubmit !== 'function') return

  extendSchemaDefinition(node, 'wrapper', {
    attrs: {
      onKeypress: (event: KeyboardEvent) => {
        if (event.key === 'Enter') {
          event.preventDefault()

          node.props.onSubmit.call(
            null,
            new SubmitEvent('submit', {
              submitter: event.target as HTMLElement,
            }),
          )
        }
      },
    },
  })
}

const addIconLabel = (node: FormKitNode) => {
  extendSchemaDefinition(node, 'label', {
    children: [
      {
        if: '$option.icon',
        $cmp: 'CommonIcon',
        props: {
          class: 'inline-flex ltr:mr-3 rtl:ml-3',
          name: '$option.icon',
          size: 'base',
        },
      },
      '$option.label',
    ],
  })
}

const handleButtonMode = (node: FormKitNode) => {
  const { props } = node

  node.addProps(['buttons'])

  const setClasses = (buttons: boolean) => {
    if (buttons) {
      props.optionsClass = 'flex flex-col grow space-y-2'
      props.optionClass = 'formkit-disabled:opacity-30'
      props.wrapperClass =
        'items-center justify-center py-2 px-4 w-full h-14 text-lg font-normal text-white bg-gray-600 rounded-xl select-none formkit-is-checked:bg-white formkit-is-checked:text-black formkit-is-checked:font-semibold'
      props.inputClass = '$reset sr-only'
    } else {
      props.inputClass =
        'h-4 w-4 border-[1.5px] border-white rounded-full bg-transparent focus:border-blue focus:bg-blue-highlight checked:focus:color-blue checked:bg-blue checked:border-blue checked:focus:bg-blue checked:hover:bg-blue'
    }
  }

  node.on('created', () => {
    if (!has(props, 'buttons')) {
      props.buttons = false
    }

    setClasses(props.buttons)

    node.on('prop:buttons', ({ payload }) => {
      setClasses(payload)
    })
  })
}

initializeFieldDefinition(radioDefinition, {
  features: [
    addOptionCheckedDataAttribute,
    addSubmitEvent,
    handleButtonMode,
    addIconLabel,
    formUpdaterTrigger(),
  ],
})

export default {
  fieldType: 'radio',
  definition: radioDefinition,
}

export type { RadioOption } from './types'
