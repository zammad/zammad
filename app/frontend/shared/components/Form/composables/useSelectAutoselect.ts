// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { type Ref, onMounted } from 'vue'
import type { FormFieldContext } from '../types/field'
import type { SelectOption } from '../fields/FieldSelect'
import type { FlatSelectOption } from '../fields/FieldTreeSelect'
import useValue from './useValue'

const useSelectAutoselect = (
  options: Ref<SelectOption[] | FlatSelectOption[]>,
  context: Ref<
    FormFieldContext<{
      autoselect?: boolean
      multiple?: boolean
    }>
  >,
) => {
  const { currentValue } = useValue(context)

  onMounted(() => {
    // Auto-select last option when and only when option list length equals one.
    if (
      context.value.autoselect &&
      !currentValue.value &&
      !context.value.disabled &&
      !context.value.multiple &&
      options.value &&
      options.value.length === 1
    ) {
      context.value.node.input(options.value[0].value)
    }
  })
}

export default useSelectAutoselect
