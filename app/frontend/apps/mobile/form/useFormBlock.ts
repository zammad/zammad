// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '@shared/components/Form/types/field'
import type { Ref } from 'vue'
import { onUnmounted } from 'vue'

// TODO maybe there is a better way to do this with FormKit?
export const useFormBlock = (
  context: Ref<FormFieldContext>,
  cb: (e: MouseEvent) => void,
) => {
  const receipt = context.value.node.on('block-click', ({ payload }) => {
    if (context.value.disabled) return

    const target = payload.target as HTMLElement | null

    // ignore link
    if (!target || target.classList.contains('formkit-link')) return
    if (target.querySelector('.formkit-link')) return
    if (target.closest('.formkit-link')) return

    cb(payload)
  })

  onUnmounted(() => {
    context.value.node.off(receipt)
  })
}
