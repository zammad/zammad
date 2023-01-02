// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import { computed, type ShallowRef, shallowRef } from 'vue'

interface FormRef {
  formNode: FormKitNode
}

// TODO: only a start, needs to be extended during the way...
const useForm = () => {
  const form: ShallowRef<FormRef | undefined> = shallowRef()

  const node = computed(() => form.value?.formNode)

  const context = computed(() => node.value?.context)

  const values = computed(() => context?.value?.value)

  const state = computed(() => context.value?.state)

  const isValid = computed(() => !!state.value?.valid)

  const isDirty = computed(() => !!state.value?.dirty)

  const isComplete = computed(() => !!state.value?.complete)

  const isSubmitted = computed(() => !!state.value?.submitted)

  const isDisabled = computed(() => {
    return !!context.value?.disabled || !!state.value?.formUpdaterProcessing
  })

  const formReset = () => {
    node.value?.reset()
  }

  const formSubmit = () => {
    node.value?.submit()
  }

  return {
    form,
    node,
    context,
    values,
    state,
    isValid,
    isDirty,
    isComplete,
    isSubmitted,
    isDisabled,
    formReset,
    formSubmit,
  }
}

export default useForm
