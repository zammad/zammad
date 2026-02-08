// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import defaultEmptyValueString from '#shared/form/features/defaultEmptyValueString.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldEditorWrapper from './FieldEditorWrapper.vue'

import type { EditorExtensionSet, FieldEditorProps } from './types.ts'
import type { FormKitInputs } from '@formkit/inputs'

declare module '@formkit/inputs' {
  // oxlint-disable eslint(no-unused-vars)
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    editor: FieldEditorProps & {
      type: 'editor'
      reset?: () => void
      inline?: boolean
      extensionSet?: EditorExtensionSet
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    editor: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(
  FieldEditorWrapper,
  [
    'groupId',
    'ticketId',
    'customerId',
    'organizationId',
    'signature',
    'meta',
    'contentType',
    'inline',
    'extensionSet',
    'reset',
  ],
  {
    features: [formUpdaterTrigger('delayed', 500), defaultEmptyValueString],
  },
)

export default {
  fieldType: 'editor',
  definition: fieldDefinition,
}
