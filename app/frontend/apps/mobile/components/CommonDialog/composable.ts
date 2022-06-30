// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { closeDialog } from '@shared/composables/useDialog'
import { useEventListener } from '@vueuse/core'
import { getCurrentInstance } from 'vue'

interface DialogProps {
  name: string
}

/**
 * @private
 */
export const useDialogState = (props: DialogProps) => {
  const vm = getCurrentInstance()

  const close = () => {
    vm?.emit('close')
    closeDialog(props.name)
  }

  useEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      close()
    }
  })

  return {
    close,
  }
}
