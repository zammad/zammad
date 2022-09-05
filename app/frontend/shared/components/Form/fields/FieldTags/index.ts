// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import addLink from '@shared/form/features/addLink'
import FieldTagsInput from './FieldTagsInput.vue'

const fieldDefinition = createInput(
  FieldTagsInput,
  ['noOptionsLabelTranslation', 'options', 'sorting', 'canCreate'],
  { features: [addLink] },
)

export default {
  fieldType: 'tags',
  definition: fieldDefinition,
}
