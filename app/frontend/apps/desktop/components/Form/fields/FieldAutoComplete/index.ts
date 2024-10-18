// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AutocompleteSelectValue } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldAutoCompleteInput from './FieldAutoCompleteInput.vue'

import type { AutoCompleteProps } from './types.ts'
import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    autocomplete: AutoCompleteProps & {
      type: 'autocomplete'
      value: AutocompleteSelectValue | null
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    autocomplete: FormKitBaseSlots<Props>
  }
}

export const autoCompleteProps = [
  'actions',
  'alternativeBackground',
  'additionalQueryParams',
  'clearable',
  'debounceInterval',
  'defaultFilter',
  'stripFilter',
  'limit',
  'multiple',
  'noOptionsLabelTranslation',
  'belongsToObjectField',
  'optionIconComponent',
  'dialogNotFoundMessage',
  'dialogEmptyMessage',
  'options',
  'initialOptionBuilder',
  'autocompleteOptionsPreprocessor',
  'sorting',
  'complexValue',
  'clearValue',
  'emptyInitialLabelText',
  'alwaysApplyDefaultFilter',
]

const fieldDefinition = createInput(
  FieldAutoCompleteInput,
  [...autoCompleteProps, 'gqlQuery'],
  { features: [addLink, formUpdaterTrigger()] },
)

export default {
  fieldType: 'autocomplete',
  definition: fieldDefinition,
}
