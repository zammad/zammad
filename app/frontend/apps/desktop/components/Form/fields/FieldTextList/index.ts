// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'

import FieldTextListInput from './FieldTextListInput.vue'

import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    textList: {
      type: 'textList'
      value?: string[] | null
      description?: string
      emptyLabel?: string
      itemLabel: string
      itemPlaceholder?: string
      addLabel: string
      editLabel: string
      removeLabel: string
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    textList: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(FieldTextListInput, [
  'description',
  'emptyLabel',
  'itemLabel',
  'itemPlaceholder',
  'addLabel',
  'editLabel',
  'removeLabel',
])

export default {
  fieldType: 'textList',
  definition: fieldDefinition,
}
