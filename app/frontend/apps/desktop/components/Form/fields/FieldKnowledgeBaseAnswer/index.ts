// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'

import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

import FieldKnowledgeBaseAnswerWrapper from './FieldKnowledgeBaseAnswerWrapper.vue'

const fieldDefinition = createInput(
  FieldKnowledgeBaseAnswerWrapper,
  [...autoCompleteProps, 'onDeactivate', 'exclude'],
  { features: [addLink] },
)

export default {
  fieldType: 'knowledgeBaseAnswer',
  definition: fieldDefinition,
}
