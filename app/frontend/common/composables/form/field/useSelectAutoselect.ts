// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { type Ref, onMounted } from 'vue'
import type { FormFieldContext } from '@common/types/form'
import type { SelectOption } from '@common/types/form/field/select'
import type { FlatSelectOption } from '@common/types/form/field/treeselect'

const useSelectAutoselect = (
  options: Ref<SelectOption[] | FlatSelectOption[]>,
  context: Ref<
    FormFieldContext<{
      autoselect?: boolean
      multiple?: boolean
    }>
  >,
) => {
  onMounted(() => {
    // Auto-select last option when and only when option list length equals one.
    if (
      context.value.autoselect &&
      // eslint-disable-next-line no-underscore-dangle
      !context.value._value &&
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
