// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { tryOnScopeDispose } from '@vueuse/shared'
import { computed, watch } from 'vue'
import { useRouter } from 'vue-router'

import type { CtiSidebarQuery } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import {
  useBrowserNotification,
  useBrowserNotificationTab,
} from '#desktop/composables/useBrowserNotification.ts'

import { useCtiSidebar } from './useCtiSidebar.ts'

type RingingCall = CtiSidebarQuery['ctiSidebar']['ringingCalls'][number]

// Tells the agent about a call that starts ringing while the window is in the
//   background, like the old interface does. Unlike there, the notification
//   goes away with the ringing, since the live updates carry that change.
export const useCtiCallNotification = () => {
  const router = useRouter()

  const { isLoaded, isLoading, isNotificationEnabled, ringingCalls } = useCtiSidebar()

  // The permission is requested centrally after login, this only checks it.
  const { permissionGranted, show } = useBrowserNotification()

  const { isNotifyingTab } = useBrowserNotificationTab()

  const isActive = computed(() => isLoaded.value && isNotificationEnabled.value)

  const notifications = new Map<string, Notification>()

  // Unset until the first list has been seen: the calls ringing once the
  //   caller notification is switched on are not new to the agent. The old
  //   interface reacts to the new call event alone, too.
  let knownCallIds: Set<string> | undefined

  const closeNotification = (id: string) => {
    notifications.get(id)?.close()
    notifications.delete(id)
  }

  const closeAll = () => {
    notifications.forEach((notification) => notification.close())
    notifications.clear()
  }

  const isNew = (call: RingingCall) =>
    call.direction === 'in' && !knownCallIds?.has(call.id) && knownCallIds !== undefined

  const notify = async (call: RingingCall) => {
    const notification = await show({
      title: i18n.t(
        'Call from %s for %s',
        call.fromComment || call.from,
        call.toComment || call.to,
      ),
      icon: '/assets/images/logo.svg',
      tag: call.id,
      dir: 'auto',
      silent: true,
    })

    if (!notification) return

    // The call may have stopped ringing in the meantime.
    if (!knownCallIds?.has(call.id)) {
      notification.close()
      return
    }

    notification.onclick = () => {
      window.focus()
      router.push({ name: 'CallerLog' })
      notification.close()
    }

    notifications.set(call.id, notification)
  }

  watch(
    [isActive, ringingCalls, isLoading],
    ([active, calls, loading], [, , wasLoading]) => {
      if (!active) {
        closeAll()
        knownCallIds = undefined
        return
      }

      const callIds = new Set(calls.map((call) => call.id))

      notifications.forEach((_, id) => {
        if (!callIds.has(id)) closeNotification(id)
      })

      // The list a load answers with is a baseline, too: the sidebar query
      //   refetches after a reconnect, so the calls that rang during the
      //   outage arrive this way. An unchanged list only turns the flag off.
      const newCalls = loading || wasLoading ? [] : calls.filter(isNew)

      knownCallIds = callIds

      if (document.hasFocus() || !isNotifyingTab.value || !permissionGranted.value) return

      newCalls.forEach(notify)
    },
    { immediate: true },
  )

  // A window in front shows the ringing calls itself.
  useEventListener(window, 'focus', closeAll)

  // The tab that took over is in front; it does not notify for these calls
  //   either, since its own list knows them already.
  watch(isNotifyingTab, (notifying) => {
    if (!notifying) closeAll()
  })

  // A notification outliving its host would have nothing to open on click.
  tryOnScopeDispose(() => {
    closeAll()
    knownCallIds = undefined
  })
}
