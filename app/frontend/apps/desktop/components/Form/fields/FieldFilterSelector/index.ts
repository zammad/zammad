// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'

import FieldFilterSelectorInput from './FieldFilterSelectorInput.vue'

const filterSelector = createInput(
  FieldFilterSelectorInput,
  ['filterAttributes', 'filterAttributesOverride', 'max', 'min'],
  {
    features: [],
  },
)

export default [
  {
    fieldType: 'filterSelector',
    definition: filterSelector,
  },
]
