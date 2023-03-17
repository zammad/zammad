// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'
import { markRaw } from 'vue'
import type { FormKitSchemaNode, FormKitTypeDefinition } from '@formkit/core'
import { cloneAny } from '@formkit/utils'
import type { FormKitSchemaExtendableSection } from '@formkit/inputs'
import { createSection } from '@formkit/inputs'
import type { FieldsCustomOptions } from './initializeFieldDefinition'
import initializeFieldDefinition from './initializeFieldDefinition'

let totalCreated = 0

const isComponent = (obj: unknown): obj is Component => {
  if (!obj) return false
  return Boolean(
    (typeof obj === 'function' && obj.length === 2) ||
      (typeof obj === 'object' &&
        !Array.isArray(obj) &&
        !('$el' in obj) &&
        !('$cmp' in obj) &&
        !('if' in obj)),
  )
}

/**
 * Wrapper around the formkit createInput function. This function adds the default initilization of the
 * field definition.
 *
 * @param schemaOrComponent - The actual input schema or component.
 * @param props - The additional props for the field.
 * @param customDefinition - Additional formkit type definition options.
 * @param options - Add some field custom options.
 * @public
 */
const createInput = (
  schemaOrComponent: FormKitSchemaNode | Component,
  props?: string[],
  customDefinition: Partial<FormKitTypeDefinition> = {},
  options: FieldsCustomOptions = {},
): FormKitTypeDefinition => {
  customDefinition.props = props

  const definition = {
    type: 'input' as const,
    ...customDefinition,
  }
  let schema: () => FormKitSchemaExtendableSection
  if (isComponent(schemaOrComponent)) {
    // eslint-disable-next-line no-plusplus
    const cmpName = `CustomSchemaComponent${totalCreated++}`
    schema = createSection('input', () => ({
      $cmp: cmpName,
      props: {
        context: '$node.context',
      },
    }))
    definition.library = { [cmpName]: markRaw(schemaOrComponent) }
  } else {
    schema = createSection('input', () => cloneAny(schemaOrComponent))
  }

  initializeFieldDefinition(definition, {}, { ...options, schema })

  return definition
}

export default createInput
