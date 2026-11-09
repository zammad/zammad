// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AutoCompleteOption } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'

import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

import FieldKnowledgeBaseAnswerWrapper from './FieldKnowledgeBaseAnswerWrapper.vue'

import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

declare module '@formkit/inputs' {
  // oxlint-disable-next-line no-unused-vars
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    knowledgeBaseAnswer: {
      type: 'knowledgeBaseAnswer'
      value?: string | null
      options?: AutoCompleteOption[]
      exclude?: string[]
      onDeactivate?: () => void
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    knowledgeBaseAnswer: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(
  FieldKnowledgeBaseAnswerWrapper,
  [...autoCompleteProps, 'onDeactivate', 'exclude'],
  { features: [addLink] },
)

export default {
  fieldType: 'knowledgeBaseAnswer',
  definition: fieldDefinition,
}
