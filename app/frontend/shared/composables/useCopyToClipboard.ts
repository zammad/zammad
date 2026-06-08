// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useClipboardItems, whenever } from '@vueuse/core'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'

export const useCopyToClipboard = () => {
  const { copy: copyClipboardItems, copied: copiedToClipboard } = useClipboardItems()
  const { notify } = useNotifications()

  const copyToClipboard = (input?: string | ClipboardItem[] | null) => {
    if (typeof input === 'undefined' || input === null) return

    let source = input

    if (typeof input === 'string') {
      source = [new ClipboardItem({ 'text/plain': input })]
    }

    copyClipboardItems(source as ClipboardItem[])
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
