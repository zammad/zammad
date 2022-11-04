// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'
import FieldAutoCompleteInput from './FieldAutoCompleteInput.vue'

export const autoCompleteProps = [
  'action',
  'actionIcon',
  'allowUnknownValues',
  'clearable',
  'debounceInterval',
  'filterInputPlaceholder',
  'filterInputValidation',
  'limit',
  'multiple',
  'noOptionsLabelTranslation',
  'belongsToObjectField',
  'optionIcon',
  'options',
  'initialOptionBuilder',
  'sorting',
]

const fieldDefinition = createInput(
  FieldAutoCompleteInput,
  [...autoCompleteProps, 'gqlQuery'],
  { features: [addLink, formUpdaterTrigger()] },
  { addArrow: true },
)

export default {
  fieldType: 'autocomplete',
  definition: fieldDefinition,
}

export type { AutoCompleteOption } from './types'
