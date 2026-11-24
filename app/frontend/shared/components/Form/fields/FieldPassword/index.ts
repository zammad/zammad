// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { password as passwordDefinition, textInput } from '@formkit/inputs'
import { useEventListener } from '@vueuse/core'
import { cloneDeep } from 'lodash-es'

import initializeFieldDefinition from '#shared/form/core/initializeFieldDefinition.ts'
import addLink from '#shared/form/features/addLink.ts'
import addSubmitEvent from '#shared/form/features/addSubmitEvent.ts'
import defaultEmptyValueString from '#shared/form/features/defaultEmptyValueString.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import { setPopulatedOnWebkitAutofill } from '#shared/form/features/setPopulatedOnWebkitAutofill.ts'

import type { FormKitNode } from '@formkit/core'

const localPasswordDefinition = cloneDeep(passwordDefinition)

const switchPasswordVisibility = (node: FormKitNode) => {
  const { props } = node

  props.suffixIconClass = 'select-none cursor-pointer'
  props.suffixIcon = 'show'
  props.onSuffixIconClick = () => {
    props.type = props.type === 'password' ? 'text' : 'password'
  }

  node.on('mounted', ({ origin }) => {
    if (origin.name !== 'password' && !props.id) return

    const suffixIcon = document.getElementById(props.id as string)?.nextElementSibling

    if (suffixIcon)
      useEventListener(suffixIcon, 'keydown', (event: KeyboardEvent) => {
        if (event.code === 'Space') props.type = props.type === 'password' ? 'text' : 'password'
      })
  })

  node.on('prop:type', ({ payload, origin }) => {
    const { props } = origin
    props.suffixIcon = payload === 'password' ? 'show' : 'hide'
  })
}

// FormKit exports password as an alias of its shared text definition, so it
//   declares the same baseline as FieldInputs. The stock input section stays:
//   a readonly password is of no use.
initializeFieldDefinition(
  localPasswordDefinition,
  {
    props: ['alternativeBackground'],
    features: [
      addLink,
      addSubmitEvent,
      switchPasswordVisibility,
      formUpdaterTrigger('delayed'),
      setPopulatedOnWebkitAutofill,
      defaultEmptyValueString,
    ],
  },
  { schema: textInput },
)

export default {
  fieldType: 'password',
  definition: localPasswordDefinition,
}
