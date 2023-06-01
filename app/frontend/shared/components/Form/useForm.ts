// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import { computed, shallowRef } from 'vue'
import type { ShallowRef } from 'vue'
import type { ObjectLike } from '#shared/types/utils.ts'
import type { FormRef, FormResetOptions, FormValues } from './types.ts'

export const useForm = () => {
  const form: ShallowRef<FormRef | undefined> = shallowRef()

  const node = computed(() => form.value?.formNode)

  const context = computed(() => node.value?.context)

  const values = computed(() => context.value?.value)

  const state = computed(() => context.value?.state)

  const isValid = computed(() => !!state.value?.valid)

  const isDirty = computed(() => !!state.value?.dirty)

  const isComplete = computed(() => !!state.value?.complete)

  const isSubmitted = computed(() => !!state.value?.submitted)

  const isDisabled = computed(() => {
    return !!context.value?.disabled || !!state.value?.formUpdaterProcessing
  })

  /**
   * User can submit form, if it is:
   * - not disabled
   * - has dirty values
   * After submit, the values should be reset to new values, so "dirty" state can update.
   * It is done automaticaly, if async `@submit` event is used. Otherwise, `formReset` should be used.
   */
  const canSubmit = computed(() => {
    if (isDisabled.value) return false
    return isDirty.value
  })

  const formReset = (
    values?: FormValues,
    object?: ObjectLike,
    options?: FormResetOptions,
  ) => {
    form.value?.resetForm(values, object, options)
  }

  const formGroupReset = (
    groupNode: FormKitNode,
    values?: FormValues,
    object?: ObjectLike,
    options?: FormResetOptions,
  ) => {
    form.value?.resetForm(values, object, options, groupNode)
  }

  const formSubmit = () => {
    node.value?.submit()
  }

  const waitForFormSettled = () => {
    return new Promise<FormKitNode>((resolve) => {
      const interval = setInterval(() => {
        if (!node.value) return

        const formNode = node.value
        clearInterval(interval)
        formNode.settled.then(() => resolve(formNode))
      })
    })
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
    canSubmit,
    formReset,
    formGroupReset,
    formSubmit,
    waitForFormSettled,
  }
}
