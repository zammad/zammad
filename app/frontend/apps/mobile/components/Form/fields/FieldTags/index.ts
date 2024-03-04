// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FieldTagsProps } from '#shared/components/Form/fields/FieldTags/types.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'
import FieldTagsInput from './FieldTagsInput.vue'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    tags: FieldTagsProps & {
      type: 'tags'
      value?: string[]
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    tags: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(
  FieldTagsInput,
  ['noOptionsLabelTranslation', 'options', 'sorting', 'canCreate'],
  { features: [addLink, formUpdaterTrigger()] },
  { addArrow: true },
)

export default {
  fieldType: 'tags',
  definition: fieldDefinition,
}
