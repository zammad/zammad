// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

import createInput from '#shared/form/core/createInput.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldRadioListInput from './FieldRadioListInput.vue'
import type { RadioListOption, RadioListOptionValue } from './types.ts'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    radioList: {
      type: 'radioList'
      value?: RadioListOptionValue | null
      options: RadioListOption[]
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    treeselect: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(FieldRadioListInput, ['options'], {
  features: [formUpdaterTrigger()],
})

export default {
  fieldType: 'radioList',
  definition: fieldDefinition,
}
