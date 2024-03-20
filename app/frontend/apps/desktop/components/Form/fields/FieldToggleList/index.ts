// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

import createInput from '#shared/form/core/createInput.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import FieldToggleListInput from './FieldToggleListInput.vue'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    toggleList: {
      type: 'toggleList'
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
