// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import createInput from '@shared/form/core/createInput'
import extendSchemaDefinition from '@shared/form/utils/extendSchemaDefinition'
import FieldEditorWrapper from './FieldEditorWrapper.vue'

const addAriaLabel = (node: FormKitNode) => {
  const { props } = node

  // Specification doesn't allow accessing non-labeled elements, which Editor is (<div />)
  // (https://html.spec.whatwg.org/multipage/forms.html#category-label)
  // So, editor has `aria-labelledby` attribute and a label with the same ID
  extendSchemaDefinition(node, 'label', {
    attrs: {
      id: props.id,
    },
  })
}

const fieldDefinition = createInput(FieldEditorWrapper, [], {
  features: [addAriaLabel],
})

export default {
  fieldType: 'editor',
  definition: fieldDefinition,
}
