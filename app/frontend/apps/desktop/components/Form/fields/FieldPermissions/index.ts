// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldPermissionsInput from './FieldPermissionsInput.vue'

import type { PermissionsProps } from './types.ts'
import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    permissions: PermissionsProps
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    permissions: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(FieldPermissionsInput, ['options'], {
  features: [formUpdaterTrigger()],
})

export default {
  fieldType: 'permissions',
  definition: fieldDefinition,
}
