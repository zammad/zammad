// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { handleConnection } from '#shared/server/connection.ts'

import { useDialog } from '#desktop/components/CommonDialog/useDialog.ts'

export const useConnection = () => {
  const dialog = useDialog({
    name: 'connection-lost',
    global: true,
    prefetch: true,
    component: () => import('#desktop/components/ConnectionLostDialog/ConnectionLostDialog.vue'),
  })

  handleConnection(
    () => {
      // Opening it again would remount it, ending a game that outlasted the previous outage.
      if (!dialog.isOpened.value) dialog.open()
    },
    // The dialog closes itself, as it stays open while its game is running.
    () => {},
  )
}
