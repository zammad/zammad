// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type { TreeSelectProps } from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import removeValuesForNonExistingOrDisabledOptions from '#shared/form/features/removeValuesForNonExistingOrDisabledOptions.ts'

import FieldTreeSelectInput from './FieldTreeSelectInput.vue'

import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    treeselect: TreeSelectProps & {
      type: 'treeselect'
      value?: SelectValue | null
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    treeselect: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(
  FieldTreeSelectInput,
  [
    'alternativeBackground',
    'clearable',
    'historicalOptions',
    'multiple',
    'noFiltering',
    'noOptionsLabelTranslation',
    'options',
    'rejectNonExistentValues',
    'sorting',
  ],
  {
    features: [
      addLink,
      formUpdaterTrigger(),
      removeValuesForNonExistingOrDisabledOptions,
    ],
  },
)

export default {
  fieldType: 'treeselect',
  definition: fieldDefinition,
}
