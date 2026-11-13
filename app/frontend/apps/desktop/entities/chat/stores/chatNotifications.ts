// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { tryOnScopeDispose } from '@vueuse/shared'
import { noop } from 'lodash-es'
import { acceptHMRUpdate, defineStore, storeToRefs } from 'pinia'
import { effectScope, nextTick, watch, type EffectScope } from 'vue'
import { useRouter } from 'vue-router'

import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'

import {
  useBrowserNotification,
  useBrowserNotificationTab,
} from '#desktop/composables/useBrowserNotification.ts'
import { useChatSessionUpdatesSubscription } from '#desktop/entities/chat/graphql/subscriptions/chatSessionUpdates.api.ts'
import type { ChatConversationMessage } from '#desktop/entities/chat/types.ts'
import { chatSessionTitle, isAgentMessage } from '#desktop/entities/chat/utils.ts'

import { useChatAgentStore } from './chatAgent.ts'
import { useChatUnreadMessagesStore } from './chatUnreadMessages.ts'

const SOUND_PATH = '/assets/sounds/chat_message.mp3'

const FOCUSED_NOTIFICATION_MS = 4000

interface ChatWindowPresence {
  isAgentIn: () => boolean
  focus: () => void
}

// The message is html; the notification shows text, with a line per block like the old interface.
const messageText = (html: string) => {
  const { body } = new DOMParser().parseFromString(
    html.replace(/<br\s*\/?>|<\/(div|p)>/g, '\n'),
    'text/html',
  )

  return body.textContent?.trim() ?? ''
}

// Tells the agent about a message of the customer in a conversation they are not in, like the old
//   interface: every tab counts it as unread, the one the agent used last plays the sound and
//   shows the browser notification. The app root creates it with the session, so it works on any
//   screen, and it is a store, so the windows of the Chat page reach it.
export const useChatNotificationsStore = defineStore('chatNotifications', () => {
  const router = useRouter()

  const { ownRunningSessions } = storeToRefs(useChatAgentStore())

  const { permissionGranted, show } = useBrowserNotification()

  const { isNotifyingTab } = useBrowserNotificationTab()

  const unreadMessages = useChatUnreadMessagesStore()

  const { unreadMessageIds } = storeToRefs(unreadMessages)

  // The windows of the Chat page, which only exists once the agent opened it in the tab.
  const windows = new Map<string, ChatWindowPresence>()

  const registerWindow = (sessionId: string, presence: ChatWindowPresence) => {
    windows.set(sessionId, presence)
  }

  const unregisterWindow = (sessionId: string) => {
    windows.delete(sessionId)
  }

  let audio: HTMLAudioElement | undefined

  const playSound = () => {
    audio ??= new Audio(SOUND_PATH)

    audio.currentTime = 0
    audio.play().catch(noop)
  }

  const notifications = new Map<string, Notification>()

  const closeNotification = (sessionId: string) => {
    notifications.get(sessionId)?.close()
    notifications.delete(sessionId)
  }

  const closeAllNotifications = () =>
    notifications.forEach((_, sessionId) => closeNotification(sessionId))

  const notify = async (sessionId: string, title: string, message: ChatConversationMessage) => {
    // The tag replaces the one still showing: one notification per conversation, with the latest message.
    const shown = await show({
      title,
      body: messageText(message.content),
      icon: '/assets/images/logo.svg',
      tag: sessionId,
      dir: 'auto',
      silent: true,
    })

    if (!shown) return

    shown.onclick = async () => {
      window.focus()

      // The page is kept alive while the agent is elsewhere; its windows are back a tick after the route.
      await router.push({ name: 'Chat' })
      await nextTick()

      windows.get(sessionId)?.focus()
      shown.close()
    }

    notifications.set(sessionId, shown)

    if (document.hasFocus()) setTimeout(() => shown.close(), FOCUSED_NOTIFICATION_MS)
  }

  const knownMessageIds = new Map<string, Set<string>>()

  // After a reconnect the window's query and the subscription can both bring a message, the second
  //   one also after the agent read it.
  const isNewMessage = (sessionId: string, messageId: string) => {
    const known = knownMessageIds.get(sessionId) ?? new Set<string>()

    if (known.has(messageId)) return false

    knownMessageIds.set(sessionId, known.add(messageId))

    return true
  }

  const onCustomerMessage = (sessionId: string, message: ChatConversationMessage) => {
    const session = ownRunningSessions.value.find((running) => running.id === sessionId)

    // What a window of a session the agent does not run brings, e.g. one found through search or
    //   one that went elsewhere, was not said to them.
    if (!session || !isNewMessage(sessionId, message.id)) return

    if (windows.get(sessionId)?.isAgentIn()) return

    unreadMessages.addUnreadMessage(sessionId, message.id)

    if (!isNotifyingTab.value) return

    playSound()

    if (permissionGranted.value) notify(sessionId, chatSessionTitle(session), message)
  }

  const listeners = new Map<string, EffectScope>()

  // The window of the conversation subscribes to the same updates; Apollo sends both one stream.
  const listen = (sessionId: string) => {
    const scope = effectScope(true)

    scope.run(() => {
      // A refused subscription is the window's to tell, which keeps quiet about one after a transfer.
      const updates = new SubscriptionHandler(
        useChatSessionUpdatesSubscription({ variables: { sessionId } }),
        {
          errorShowNotification: false,
        },
      )

      updates.onResult(({ data }) => {
        const message = data?.chatSessionUpdates.message

        if (message && !isAgentMessage(message)) onCustomerMessage(sessionId, message)
      })
    })

    listeners.set(sessionId, scope)
  }

  // A window still open for the conversation keeps its count until the agent reads or closes it.
  const stopListening = (sessionId: string) => {
    listeners.get(sessionId)?.stop()
    listeners.delete(sessionId)
    knownMessageIds.delete(sessionId)

    if (!windows.has(sessionId)) unreadMessages.clearUnreadMessages(sessionId)
  }

  watch(
    () => ownRunningSessions.value.map((session) => session.id),
    (runningIds) => {
      runningIds.forEach((sessionId) => {
        if (!listeners.has(sessionId)) listen(sessionId)
      })

      listeners.forEach((_, sessionId) => {
        if (!runningIds.includes(sessionId)) stopListening(sessionId)
      })
    },
    { immediate: true },
  )

  // A conversation without unread messages needs no notification.
  watch(
    () => [...unreadMessageIds.value.keys()],
    (unreadSessionIds) => {
      notifications.forEach((_, sessionId) => {
        if (!unreadSessionIds.includes(sessionId)) closeNotification(sessionId)
      })
    },
  )

  useEventListener(window, 'focus', closeAllNotifications)

  watch(isNotifyingTab, (notifying) => {
    if (!notifying) closeAllNotifications()
  })

  // The listeners are scopes of their own, which the store's end does not reach.
  tryOnScopeDispose(() => {
    listeners.forEach((scope) => scope.stop())
    closeAllNotifications()
  })

  return { registerWindow, unregisterWindow, onCustomerMessage }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useChatNotificationsStore, import.meta.hot))
}
