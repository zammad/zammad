// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useForm } from '../useForm.ts'

import type { FormRef } from '../types.ts'
import type { Ref } from 'vue'

export const useClearFormInput = (formRef: Ref<FormRef | undefined>, fieldName: string) => {
  const { updateFieldValues } = useForm(formRef)

  const clearAndFocus = () => {
    updateFieldValues({
      [fieldName]: '',
    })

    const inputField = document.querySelector(
      `[name="${CSS.escape(fieldName)}"]`,
    ) as HTMLInputElement
    if (!inputField) return

    requestAnimationFrame(() => {
      inputField.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
      inputField.focus()
    })
  }

  return {
    clearAndFocus,
  }
}
