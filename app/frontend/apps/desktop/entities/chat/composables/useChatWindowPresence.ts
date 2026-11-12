// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { tryOnScopeDispose } from '@vueuse/shared'
import { toValue, type MaybeRefOrGetter } from 'vue'

import type { ChatConversationMessage } from '#desktop/entities/chat/types.ts'
import { isAgentMessage } from '#desktop/entities/chat/utils.ts'

import { useChatNotificationsStore } from '../stores/chatNotifications.ts'
import { useChatUnreadMessagesStore } from '../stores/chatUnreadMessages.ts'

interface WindowOptions {
  windowElement: MaybeRefOrGetter<HTMLElement | null | undefined>
  // None once the conversation is not the agent's to write into.
  inputElement: MaybeRefOrGetter<HTMLElement | null | undefined>
  isOver: MaybeRefOrGetter<boolean>
  focusWindow: () => void
}

// What a chat window and the notification tell each other: a message for the window whose message
//   input the agent is in is read right away, a click on the notification moves the focus into the
//   window, and the window passes on what its query brought that the subscription did not.
export const useChatWindowPresence = (
  sessionId: MaybeRefOrGetter<string>,
  { windowElement, inputElement, isOver, focusWindow }: WindowOptions,
) => {
  const notifications = useChatNotificationsStore()

  const { clearUnreadMessages } = useChatUnreadMessagesStore()

  const markRead = () => {
    clearUnreadMessages(toValue(sessionId))
  }

  notifications.registerWindow(toValue(sessionId), {
    isAgentIn: () =>
      document.hasFocus() && Boolean(toValue(inputElement)?.contains(document.activeElement)),
    // With the focus in the input already, moving it there reads nothing.
    focus: () => {
      focusWindow()

      if (document.activeElement === toValue(inputElement)) markRead()
    },
  })

  // A tab that gets the focus back hands it to the input the agent left: that is not them coming
  //   to it, so only a click into it or writing reads the conversation then.
  let isFocusGivenBack = false

  useEventListener(window, 'blur', () => {
    isFocusGivenBack = document.activeElement === toValue(inputElement)
  })

  // The agent reads the conversation by coming to its message input, like the old interface on
  //   arrival: reading back in the thread, or going to the first unread message, keeps the mark.
  //   Heard on the window, as the input of a conversation that loads after a click on the
  //   notification takes the focus the moment it appears, before a listener on it is bound.
  useEventListener(windowElement, 'focusin', (event) => {
    if (event.target !== toValue(inputElement)) return

    if (isFocusGivenBack) isFocusGivenBack = false
    else markRead()
  })

  useEventListener(windowElement, ['click', 'input'], (event) => {
    if (toValue(inputElement)?.contains(event.target as Node)) markRead()
  })

  // One that is over has no input to come to, so a click into its window reads it; one that still
  //   loads, or failed to, has shown the agent nothing yet.
  useEventListener(windowElement, 'click', () => {
    if (toValue(isOver)) markRead()
  })

  // The subscription does not replay what was said while the connection was down; the window's
  //   query does, and the agent is told about it the same way.
  const reportMissedMessage = (message: ChatConversationMessage) => {
    if (!isAgentMessage(message)) notifications.onCustomerMessage(toValue(sessionId), message)
  }

  // A closed window takes its unread messages out of the navigation's count.
  tryOnScopeDispose(() => {
    notifications.unregisterWindow(toValue(sessionId))
    markRead()
  })

  return { reportMissedMessage }
}
