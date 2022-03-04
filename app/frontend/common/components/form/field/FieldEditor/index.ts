// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import FieldEditorInner from '@common/components/form/field/FieldEditor/FieldEditorInner.vue'
import createInput from '@common/form/core/createInput'

const fieldDefinition = createInput(FieldEditorInner)

export default {
  fieldType: 'editor',
  definition: fieldDefinition,
}
