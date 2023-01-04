// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'
import { type FormFieldContext } from '../types/field'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const useValue = <T = any>(
  context: Ref<FormFieldContext<{ multiple?: boolean }>>,
) => {
  const currentValue = computed(() => context.value._value as T)

  const hasValue = computed(() => {
    return context.value.fns.hasValue(currentValue.value)
  })

  const valueContainer = computed(() =>
    context.value.multiple ? currentValue.value : [currentValue.value],
  )

  const isCurrentValue = (value: T) => {
    if (!hasValue.value) return false
    return (valueContainer.value as unknown as T[]).includes(value)
  }

  const clearValue = (asyncSettling = true) => {
    if (!hasValue.value) return
    context.value.node.input(undefined, asyncSettling)
  }

  const localValue = computed({
    get: () => currentValue.value,
    set: (value) => {
      context.value.node.input(value)
    },
  })

  return {
    localValue,
    currentValue,
    hasValue,
    valueContainer,
    isCurrentValue,
    clearValue,
  }
}

export default useValue
