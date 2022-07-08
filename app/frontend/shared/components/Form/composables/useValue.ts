// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'
import { type FormFieldContext } from '../types/field'

const useValue = (context: Ref<FormFieldContext<{ multiple?: boolean }>>) => {
  // eslint-disable-next-line no-underscore-dangle
  const currentValue = computed(() => context.value._value)

  const hasValue = computed(() => {
    return context.value.fns.hasValue(currentValue.value)
  })

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
