// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useUserCurrentCallerNotificationUpdateMutation } from '#desktop/entities/cti/graphql/mutations/userCurrentCallerNotificationUpdate.api.ts'

export const useCallerNotificationToggle = () => {
  const session = useSessionStore()

  // Backed by the user preference `cti`, the same key the old interface reads
  //   and writes, so both interfaces stay in sync.
  const isEnabled = computed(() =>
    Boolean(session.user?.personalSettings?.callerNotificationEnabled),
  )

  const updateMutation = new MutationHandler(useUserCurrentCallerNotificationUpdateMutation(), {
    errorNotificationMessage: __('The caller notification could not be updated.'),
  })

  // Replaced rather than mutated in place: query results are frozen.
  const setLocalState = (enabled: boolean) => {
    if (!session.user?.personalSettings) return

    session.user.personalSettings = {
      ...session.user.personalSettings,
      callerNotificationEnabled: enabled,
    }
  }

  // Optimistic like the theme store: the switch follows the click, and a failed write puts it back.
  const setEnabled = (enabled: boolean) => {
    const previous = isEnabled.value

    setLocalState(enabled)

    return updateMutation.send({ enabled }).catch(() => setLocalState(previous))
  }

  return { isEnabled, setEnabled }
}
