// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'
import { type FormFieldContext } from '@common/types/form'

const useValue = (context: Ref<FormFieldContext<{ multiple?: boolean }>>) => {
  // eslint-disable-next-line no-underscore-dangle
  const currentValue = computed(() => context.value._value)

  const hasValue = computed(() =>
    context.value.fns.hasValue(currentValue.value),
  )

  const valueContainer = computed(() =>
    context.value.multiple ? currentValue.value : [currentValue.value],
  )

  const isCurrentValue = (value: unknown) => {
    if (!hasValue.value) return false
    return valueContainer.value.includes(value)
  }

  const clearValue = () => {
    if (!hasValue.value) return
    context.value.node.input(undefined)
  }

  return {
    currentValue,
    hasValue,
    valueContainer,
    isCurrentValue,
    clearValue,
  }
}

export default useValue
