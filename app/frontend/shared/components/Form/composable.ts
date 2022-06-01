// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import { computed, type Ref, ref } from 'vue'

interface FormRef {
  formNode: FormKitNode
}

// TODO: only a start, needs to be extended during the way...
const useForm = () => {
  const form: Ref<FormRef | undefined> = ref()

  const node = computed(() => form.value?.formNode)

  const context = computed(() => node.value?.context)

  const state = computed(() => context.value?.state)

  const isValid = computed(() => !!state.value?.valid)

  const isDirty = computed(() => !!state.value?.dirty)

  const isComplete = computed(() => !!state.value?.complete)

  const isSubmitted = computed(() => !!state.value?.submitted)

  const isDisabled = computed(() => !!context.value?.disabled)

  const formReset = () => {
    node.value?.reset()
  }

  return {
    form,
    node,
    context,
    state,
    isValid,
    isDirty,
    isComplete,
    isSubmitted,
    isDisabled,
    formReset,
  }
}

export default useForm
