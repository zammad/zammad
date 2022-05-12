// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'
import type { FormKitTypeDefinition } from '@formkit/core'
import type { FormKitInputSchema } from '@formkit/inputs'
import { createInput as createFormKitInput } from '@formkit/vue'
import initializeFieldDefinition from './initializeFieldDefinition'

/**
 * Wrapper around the formkit createInput function. This function adds the default initilization of the
 * field definition.
 *
 * @param schemaOrComponent - The actual input schema or component.
 * @param props - The additional props for the field.
 * @param options - Additional formkit type definition options.
 * @param addDefaultProps - Add the default props to the field definition.
 * @param addDefaultFeatures - Add the default features to the field definition.
 * @public
 */
const createInput = (
  schemaOrComponent: FormKitInputSchema | Component,
  props?: string[],
  options: Partial<FormKitTypeDefinition> = {},
  addDefaultProps = true,
  addDefaultFeatures = true,
): FormKitTypeDefinition => {
  const fieldDefinition = createFormKitInput(schemaOrComponent, {
    props,
    ...options,
  })

  initializeFieldDefinition(
    fieldDefinition,
    {},
    addDefaultProps,
    addDefaultFeatures,
  )

  return fieldDefinition
}

export default createInput
