// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import FieldInputSearch from './FieldSearch.vue'

const fieldDefinition = createInput(FieldInputSearch, ['noBorder'])

export default {
  fieldType: 'search',
  definition: fieldDefinition,
}
