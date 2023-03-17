// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'
import FieldToggleInput from './FieldToggleInput.vue'

const fieldDefinition = createInput(FieldToggleInput, ['variants'], {
  features: [addLink, formUpdaterTrigger()],
})

export default {
  fieldType: 'toggle',
  definition: fieldDefinition,
}
