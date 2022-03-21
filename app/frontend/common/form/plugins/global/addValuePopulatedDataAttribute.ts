// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from '@apollo/client/utilities'
import { FormKitNode, FormKitExtendableSchemaRoot } from '@formkit/core'

const addValuePopulatedDataAttribute = (node: FormKitNode) => {
  const { props, context } = node

  if (!props.definition || !context || node.type !== 'input') return

  // Adds a helper function to check the existing value inside of the context.
  context.fns.hasValue = (value) => !!value

  const definition = cloneDeep(props.definition)

  const originalSchema = definition.schema as FormKitExtendableSchemaRoot

  definition.schema = (extensions) => {
    const localExtensions = {
      ...extensions,
      outer: {
        attrs: {
          'data-populated': {
            if: '$fns.hasValue($_value)',
            then: 'true',
            else: undefined,
          },
        },
      },
    }
    return originalSchema(localExtensions)
  }

  props.definition = definition
}

export default addValuePopulatedDataAttribute
