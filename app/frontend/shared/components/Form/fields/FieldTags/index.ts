// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'
import FieldTagsInput from './FieldTagsInput.vue'

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
