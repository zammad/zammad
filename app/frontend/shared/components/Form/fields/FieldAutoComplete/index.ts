// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import FieldAutoCompleteInput from './FieldAutoCompleteInput.vue'

export const autoCompleteProps = [
  'action',
  'actionIcon',
  'autoselect',
  'clearable',
  'debounceInterval',
  'limit',
  'multiple',
  'noOptionsLabelTranslation',
  'optionIcon',
  'options',
  'sorting',
]

const fieldDefinition = createInput(
  FieldAutoCompleteInput,
  [...autoCompleteProps, 'gqlQuery'],
  { features: [addLink] },
)

export default {
  fieldType: 'autocomplete',
  definition: fieldDefinition,
}

export type { AutoCompleteOption } from './types'
