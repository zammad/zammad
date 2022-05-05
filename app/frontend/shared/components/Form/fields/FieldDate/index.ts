// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createInput from '@shared/form/core/createInput'
import FieldDateTimeInput from '@shared/components/Form/fields/FieldDate/FieldDateTimeInput.vue'

const props = ['maxDate', 'minDate', 'futureOnly']

const dateFieldDefinition = createInput(FieldDateTimeInput, props)
const dateTimeFieldDefinition = createInput(
  {
    $cmp: FieldDateTimeInput,
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
    definition: dateTimeFieldDefinition,
  },
]
