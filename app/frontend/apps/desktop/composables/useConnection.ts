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
    () => dialog.open(),
    () => dialog.close(),
  )
}
