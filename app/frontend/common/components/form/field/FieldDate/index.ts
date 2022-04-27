// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@common/form/core/createInput'
import FieldDateInput from '@common/components/form/field/FieldDate/FieldDateInput.vue'

const props = ['maxDate', 'minDate', 'futureOnly']

const dateFieldDefinition = createInput(FieldDateInput, props)
const datetimeFieldDefinition = createInput(
  {
    $cmp: FieldDateInput,
    props: {
      context: '$node.context',
      time: true,
    },
  },
  props,
)

export default [
  {
    fieldType: 'date',
    definition: dateFieldDefinition,
  },
  {
    fieldType: 'datetimeLocal',
    definition: datetimeFieldDefinition,
  },
]
