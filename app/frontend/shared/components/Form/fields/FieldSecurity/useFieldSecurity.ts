// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref, type WritableComputedRef } from 'vue'

import {
  EnumSecurityStateType,
  type FieldSecurityContext,
  type SecurityOption,
  type SecurityValue,
} from './types.ts'

import type { FormFieldContext } from '../../types/field.ts'

export const useFieldSecurity = (
  context: Ref<FormFieldContext<FieldSecurityContext>>,
  localValue: WritableComputedRef<SecurityValue>,
) => {
  const securityMethods = computed(() => {
    return Object.keys(context.value.securityAllowed || {}).sort((a) => {
      if (a === EnumSecurityStateType.Pgp) return -1
      if (a === EnumSecurityStateType.Smime) return 1
      return 0
    }) as EnumSecurityStateType[]
  })

  const previewMethod = computed(
    () =>
      localValue.value?.method ??
      // smime should have priority
      (securityMethods.value.find(
        (value) => value === EnumSecurityStateType.Smime,
      ) ||
        securityMethods.value[0]),
  )

  const isCurrentSecurityOption = (option: SecurityOption) =>
    localValue.value?.options.includes(option) ?? false

  const isSecurityOptionDisabled = (option: SecurityOption) =>
    context.value.disabled ||
    !context.value.securityAllowed?.[previewMethod.value]?.includes(option)

  const defaultOptions = (method: EnumSecurityStateType) =>
    context.value.securityDefaultOptions?.[method] || []

  const filterOptions = (
    method: EnumSecurityStateType,
    options: SecurityOption[],
  ) => {
    return options
      .filter((option) =>
        context.value.securityAllowed?.[method]?.includes(option),
      )
      .sort()
  }

  const changeSecurityState = (method: EnumSecurityStateType) => {
    // Reset the default behavior of the chosen method and remove unsupported options.
    const newOptions = filterOptions(method, defaultOptions(method))
    localValue.value = {
      method,
      options: newOptions,
    }
  }

  return {
    securityMethods,
    previewMethod,
    isCurrentSecurityOption,
    isSecurityOptionDisabled,
    changeSecurityState,
  }
}
