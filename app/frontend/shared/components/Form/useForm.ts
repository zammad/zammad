// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, shallowRef } from 'vue'

import type { MutationSendError } from '#shared/types/error.ts'
import type { FormUpdaterOptions } from '#shared/types/form.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { setErrors } from './utils.ts'

import type {
  FormRef,
  FormResetOptions,
  FormFieldValue,
  FormValues,
  FormSchemaField,
} from './types.ts'
import type { FormKitNode } from '@formkit/core'
import type { ShallowRef, Ref } from 'vue'

export const useForm = <T = FormValues>(formRef?: Ref<FormRef | undefined>) => {
  const form: ShallowRef<FormRef | undefined> = formRef || shallowRef()

  const node = computed(() => form.value?.formNode)

  const context = computed(() => node.value?.context)

  const nodeValues = computed<FormValues>(() => context.value?.value)

  const state = computed(() => context.value?.state)

  const isValid = computed(() => !!state.value?.valid)

  const isDirty = computed(() => !!state.value?.dirty)

  const isComplete = computed(() => !!state.value?.complete)

  const isSubmitted = computed(() => !!state.value?.submitted)

  const isDisabled = computed(() => {
    return !!context.value?.disabled || !!state.value?.formUpdaterProcessing
  })

  const formNodeId = computed(() => {
    return context.value?.id
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

  const onChangedField = (
    name: string,
    callback: (
      newValue: FormFieldValue,
      oldValue: FormFieldValue,
      node: FormKitNode,
    ) => void,
  ) => {
    const registerChangeEvent = (node: FormKitNode) => {
      node.on(`changed:${name}`, ({ payload }) => {
        callback(payload.newValue, payload.oldValue, payload.fieldNode)
      })
    }

    if (node.value) {
      registerChangeEvent(node.value)
    } else {
      waitForFormSettled().then((node) => {
        registerChangeEvent(node)
      })
    }
  }

  const updateFieldValues = (fieldValues: Record<string, FormFieldValue>) => {
    const changedFieldValues: Record<
      string,
      Pick<FormSchemaField, 'value'>
    > = {}

    Object.keys(fieldValues).forEach((fieldName) => {
      changedFieldValues[fieldName] = {
        value: fieldValues[fieldName],
      }
    })

    form.value?.updateChangedFields(changedFieldValues)
  }

  const values = computed<T>(() => {
    return (form.value?.values || {}) as T
  })

  const formSetErrors = (errors: MutationSendError) => {
    if (!node.value) return

    setErrors(node.value, errors)
  }

  const triggerFormUpdater = (options?: FormUpdaterOptions) => {
    form.value?.triggerFormUpdater(options)
  }

  return {
    form,
    node,
    context,
    nodeValues,
    values,
    state,
    isValid,
    isDirty,
    isComplete,
    isSubmitted,
    isDisabled,
    formNodeId,
    canSubmit,
    formSetErrors,
    formReset,
    formGroupReset,
    formSubmit,
    waitForFormSettled,
    updateFieldValues,
    onChangedField,
    triggerFormUpdater,
  }
}
