// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldToggleListInput from './FieldToggleListInput.vue'

import type { ToggleListOption, ToggleListOptionValue } from './types.ts'
import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    toggleList: {
      type: 'toggleList'
      value?: ToggleListOptionValue | null
      options: ToggleListOption[]
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    treeselect: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(FieldToggleListInput, ['options'], {
  features: [formUpdaterTrigger()],
})

export default {
  fieldType: 'toggleList',
  definition: fieldDefinition,
}
