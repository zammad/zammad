// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useClipboard, whenever } from '@vueuse/core'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'

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
      message: __('Copied.'), // TODO should this not be something given to the composable for a more meaningful message?
    })
  })

  return {
    copiedToClipboard,
    copyToClipboard,
  }
}
