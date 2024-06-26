// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldAutoCompleteInput from './FieldAutoCompleteInput.vue'

export const autoCompleteProps = [
  'action',
  'actionIcon',
  'actionLabel',
  'additionalQueryParams',
  'allowUnknownValues',
  'clearable',
  'debounceInterval',
  'defaultFilter',
  'filterInputPlaceholder',
  'filterInputValidation',
  'limit',
  'multiple',
  'noOptionsLabelTranslation',
  'belongsToObjectField',
  'optionIcon',
  'dialogNotFoundMessage',
  'dialogEmptyMessage',
  'options',
  'initialOptionBuilder',
  'sorting',
  'complexValue',
  'clearValue',
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
