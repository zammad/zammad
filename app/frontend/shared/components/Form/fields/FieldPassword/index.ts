// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { password as passwordDefinition } from '@formkit/inputs'
import { cloneDeep } from 'lodash-es'

import initializeFieldDefinition from '#shared/form/core/initializeFieldDefinition.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import type { FormKitNode } from '@formkit/core'

const localPasswordDefinition = cloneDeep(passwordDefinition)

const switchPasswordVisibility = (node: FormKitNode) => {
  const { props } = node

  props.suffixIconClass = 'select-none cursor-pointer'
  props.suffixIcon = 'show'
  props.onSuffixIconClick = () => {
    props.type = props.type === 'password' ? 'text' : 'password'
  }

  node.on('prop:type', ({ payload, origin }) => {
    const { props } = origin
    props.suffixIcon = payload === 'password' ? 'show' : 'hide'
  })
}

initializeFieldDefinition(localPasswordDefinition, {
  features: [switchPasswordVisibility, formUpdaterTrigger('delayed')],
})

export default {
  fieldType: 'password',
  definition: localPasswordDefinition,
}
