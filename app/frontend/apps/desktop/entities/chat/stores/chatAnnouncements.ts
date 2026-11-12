// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener, useTimeoutFn } from '@vueuse/core'
import { tryOnScopeDispose } from '@vueuse/shared'
import { noop } from 'lodash-es'
import { acceptHMRUpdate, defineStore, storeToRefs } from 'pinia'
import { computed, watch } from 'vue'
import { useRouter } from 'vue-router'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import {
  useBrowserNotification,
  useBrowserNotificationTab,
} from '#desktop/composables/useBrowserNotification.ts'

import { useChatAgentStore } from './chatAgent.ts'
import { useChatPreferencesStore } from './chatPreferences.ts'

const SOUND_PATH = '/assets/sounds/chat_new.mp3'

// Like the old interface, a notification in front of the agent goes away by itself.
const FOCUSED_NOTIFICATION_MS = 4000

// The default of the setting, which comes as a string.
const DEFAULT_IDLE_TIMEOUT_SECONDS = 120

// Tells an available agent about a customer who starts waiting, and takes them off the chat when
//   nobody answers, like the old interface does. A store for its lifetime, not for a state.
export const useChatAnnouncementsStore = defineStore('chatAnnouncements', () => {
  const router = useRouter()

  const application = useApplicationStore()

  const { notify } = useNotifications()

  const chatAgent = useChatAgentStore()

  const { isLoaded, isAvailable, waitingCount, ownRunningSessions } = storeToRefs(chatAgent)

  const { isLimitReached } = storeToRefs(useChatPreferencesStore())

  // The permission is requested centrally after login, this only checks it.
  const { permissionGranted, show } = useBrowserNotification()

  const { isNotifyingTab } = useBrowserNotificationTab()

  let audio: HTMLAudioElement | undefined

  const playSound = () => {
    audio ??= new Audio(SOUND_PATH)

    audio.currentTime = 0
    audio.play().catch(noop)
  }

  // Preloaded once the agent can need it, so the first customer is not announced late.
  watch(
    isAvailable,
    (available) => {
      if (!available || audio) return

      audio = new Audio(SOUND_PATH)
      audio.preload = 'auto'
    },
    { immediate: true },
  )

  let notification: Notification | undefined

  const closeNotification = () => {
    notification?.close()
    notification = undefined
  }

  const announce = async (count: number) => {
    playSound()

    if (!permissionGranted.value) return

    const title =
      count === 1
        ? i18n.t('%s waiting customer', '1')
        : i18n.t('%s waiting customers', String(count))

    // The same tag replaces the one still showing: one notification, with the latest count.
    const shown = await show({
      title,
      icon: '/assets/images/logo.svg',
      tag: 'chat-waiting-customers',
      dir: 'auto',
      silent: true,
    })

    if (!shown) return

    shown.onclick = () => {
      window.focus()
      router.push({ name: 'Chat' })
      shown.close()
    }

    notification = shown

    if (document.hasFocus()) setTimeout(() => shown.close(), FOCUSED_NOTIFICATION_MS)
  }

  // Unset until the first result has been seen: the customers waiting by then, or when the agent
  //   switches available, are not new to them.
  let lastWaitingCount: number | undefined

  watch(
    [isLoaded, waitingCount],
    ([loaded, count]) => {
      if (!loaded) {
        lastWaitingCount = undefined
        return
      }

      const previous = lastWaitingCount

      lastWaitingCount = count

      if (previous === undefined || count <= previous) return
      if (!isAvailable.value || !isNotifyingTab.value) return

      announce(count)
    },
    { immediate: true },
  )

  // A window in front shows the waiting customers itself.
  useEventListener(window, 'focus', closeNotification)

  watch(isNotifyingTab, (notifying) => {
    if (!notifying) closeNotification()
  })

  // The setting is free text: like the old interface, "45s" counts as 45 and anything without a
  //   positive number as the default.
  const idleTimeout = computed(() => {
    const seconds = Number.parseInt(String(application.config.chat_agent_idle_timeout), 10)

    return (seconds > 0 ? seconds : DEFAULT_IDLE_TIMEOUT_SECONDS) * 1000
  })

  // At their chat limit the agent cannot accept anyone, so a customer who keeps waiting is no reason
  //   to switch them off, like in the old interface.
  const isWaitingForAnswer = computed(
    () => isLoaded.value && isAvailable.value && waitingCount.value > 0 && !isLimitReached.value,
  )

  // Every tab runs the timer and writes the same availability; only the one the agent used last tells them.
  const switchOff = async () => {
    const switched = await chatAgent.setAvailable(false)

    if (switched && isNotifyingTab.value) {
      notify({
        id: 'chat-idle-timeout',
        type: NotificationTypes.Info,
        message: __('Chat not answered, automatically set to offline.'),
        unique: true,
        persistent: true,
      })
    }

    return switched
  }

  const { start: startTimeout, stop: stopTimeout } = useTimeoutFn(
    async () => {
      // A write that fails leaves the agent available, so the next try comes after another idle period.
      if (!(await switchOff()) && isWaitingForAnswer.value) startTimeout()
    },
    idleTimeout,
    { immediate: false },
  )

  watch(isWaitingForAnswer, (waiting) => (waiting ? startTimeout() : stopTimeout()), {
    immediate: true,
  })

  // Taking a customer starts the wait over for the ones who are still waiting.
  watch(
    () => ownRunningSessions.value.length,
    (count, previous) => {
      if (count > previous && isWaitingForAnswer.value) startTimeout()
    },
  )

  tryOnScopeDispose(() => {
    closeNotification()
    stopTimeout()
  })

  return {}
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useChatAnnouncementsStore, import.meta.hot))
}
