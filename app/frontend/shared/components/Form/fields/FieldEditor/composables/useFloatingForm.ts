// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, onMounted, useTemplateRef } from 'vue'

import { useForm } from '#shared/components/Form/useForm.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'

// A form the editor opens in a floating popover, rendered in an element with `ref="container"`:
//   it keeps the focus, starting on its first input.
export const useFloatingForm = () => {
  const formHelpers = useForm()

  const container = useTemplateRef<HTMLElement>('container')

  const { activateTabTrap } = useTrapTab(container)

  onMounted(async () => {
    await nextTick()
    activateTabTrap()
    await formHelpers.waitForFormSettled()

    // FormKit does not honour autofocus, so the input is focused by hand.
    container.value?.querySelector('input')?.focus()
  })

  return formHelpers
}
