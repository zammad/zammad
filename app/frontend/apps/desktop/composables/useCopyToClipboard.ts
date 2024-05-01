// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useClipboard, whenever } from '@vueuse/core'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'

export const useCopyToClipboard = () => {
  const { copy, copied: copiedToClipboard } = useClipboard()
  const { notify } = useNotifications()

  const copyToClipboard = (input?: string | null) => {
    if (typeof input === 'undefined' || input === null) return
    copy(input)
  }

  whenever(copiedToClipboard, () => {
    notify({
      id: 'copied-to-clipboard',
      type: NotificationTypes.Success,
      message: __('Copied!'),
    })
  })

  return {
    copiedToClipboard,
    copyToClipboard,
  }
}
