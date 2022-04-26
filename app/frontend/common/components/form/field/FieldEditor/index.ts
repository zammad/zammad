// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import FieldEditorInput from '@common/components/form/field/FieldEditor/FieldEditorInput.vue'
import createInput from '@common/form/core/createInput'
import { FormKitExtendableSchemaRoot, FormKitNode } from '@formkit/core'
import { cloneDeep } from 'lodash-es'

function addAriaLabel(node: FormKitNode) {
  const { props } = node

  if (!props.definition) return

  const definition = cloneDeep(props.definition)

  const originalSchema = definition.schema as FormKitExtendableSchemaRoot

  // Specification doesn't allow accessing non-labeled elements, which Editor is (<div />)
  // (https://html.spec.whatwg.org/multipage/forms.html#category-label)
  // So, editor has `aria-labelledby` attribute and a label with the same ID
  definition.schema = (definition) => {
    const localDefinition = {
      ...definition,
      label: {
        attrs: {
          id: props.id,
        },
      },
    }
    return originalSchema(localDefinition)
  }

  props.definition = definition
}

const fieldDefinition = createInput(FieldEditorInput, [], {
  features: [addAriaLabel],
})

export default {
  fieldType: 'editor',
  definition: fieldDefinition,
}
