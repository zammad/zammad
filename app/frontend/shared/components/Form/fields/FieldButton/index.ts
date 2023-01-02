// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import { has } from '@formkit/utils'
import {
  button as buttonDefinition,
  submit as submitDefinition,
} from '@formkit/inputs'
import type {
  FormFieldsTypeDefinition,
  FormFieldType,
} from '@shared/types/form'
import initializeFieldDefinition from '@shared/form/core/initializeFieldDefinition'
import extendSchemaDefinition from '@shared/form/utils/extendSchemaDefinition'
import addIcon from '@shared/form/features/addIcon'
import { ButtonVariant } from './types'

// TODO: Build-In loading cycle funcitonality for the buttons or at least a disabled-state when loading is in progress?

const addVariantDataAttribute = (node: FormKitNode) => {
  extendSchemaDefinition(node, 'wrapper', {
    attrs: {
      'data-variant': '$variant',
    },
  })
}

const setVariantDefault = (node: FormKitNode) => {
  const { props } = node

  node.addProps(['variant'])

  node.on('created', () => {
    if (!has(props, 'variant')) {
      props.variant = ButtonVariant.Primary
    }
  })
}

const buttonFieldDefinitionList: FormFieldsTypeDefinition = {
  button: buttonDefinition,
  submit: submitDefinition,
}

const buttonInputs: FormFieldType[] = []

Object.keys(buttonFieldDefinitionList).forEach((buttonType) => {
  initializeFieldDefinition(buttonFieldDefinitionList[buttonType], {
    features: [setVariantDefault, addVariantDataAttribute, addIcon],
  })

  buttonInputs.push({
    fieldType: buttonType,
    definition: buttonFieldDefinitionList[buttonType],
  })
})

export default buttonInputs
