// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useThrottleFn, useTimeoutFn } from '@vueuse/core'
import { storeToRefs } from 'pinia'
import { computed, ref, toValue, watch, type MaybeRefOrGetter } from 'vue'

import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import getUuid from '#shared/utils/getUuid.ts'

import { useChatSessionEndMutation } from '#desktop/entities/chat/graphql/mutations/chatSessionEnd.api.ts'
import { useChatSessionMessageAddMutation } from '#desktop/entities/chat/graphql/mutations/chatSessionMessageAdd.api.ts'
import { useChatSessionRenameMutation } from '#desktop/entities/chat/graphql/mutations/chatSessionRename.api.ts'
import { useChatSessionTransferMutation } from '#desktop/entities/chat/graphql/mutations/chatSessionTransfer.api.ts'
import { useChatSessionTypingMutation } from '#desktop/entities/chat/graphql/mutations/chatSessionTyping.api.ts'
import { useChatSessionQuery } from '#desktop/entities/chat/graphql/queries/chatSession.api.ts'
import { useChatSessionUpdatesSubscription } from '#desktop/entities/chat/graphql/subscriptions/chatSessionUpdates.api.ts'
import type {
  ChatConversationMessage,
  ChatEnding,
  ChatThreadEntry,
} from '#desktop/entities/chat/types.ts'
import {
  chatSessionName,
  chatSessionTitle,
  formatChatAgentName,
} from '#desktop/entities/chat/utils.ts'

import { useChatAgentStore } from '../stores/chatAgent.ts'
import { useChatUnreadMessagesStore } from '../stores/chatUnreadMessages.ts'

import { useChatWindowPresence } from './useChatWindowPresence.ts'

// How long the indicator stays after the last sign of typing, like the old interface.
const TYPING_INDICATOR_MS = 2000

// Often enough to keep the indicator of the customer up, rarely enough to spare the server.
const TYPING_SIGNAL_INTERVAL_MS = 2000

interface Options {
  // The window and its message input, for the notification about a message of the customer while
  //   the agent is not in it.
  windowElement: MaybeRefOrGetter<HTMLElement | null | undefined>
  inputElement: MaybeRefOrGetter<HTMLElement | null | undefined>
  focusWindow: () => void
}

// What one chat window shows and does: the history of a session of the agent, what the customer
//   does and says while it is open, and the agent's own messages, typing and end.
export const useChatConversation = (
  sessionId: MaybeRefOrGetter<string>,
  { windowElement, inputElement, focusWindow }: Options,
) => {
  // The subscription does not replay what was said while the connection was down.
  const sessionQuery = new QueryHandler(
    useChatSessionQuery({ variables: { sessionId }, fetchPolicy: 'network-only' }),
    { triggerRefetchOnConnectionReconnect: true },
  )

  const sessionResult = sessionQuery.result()

  const session = computed(() => sessionResult.value?.chatSession)

  const isLoading = sessionQuery.loading()

  const loadError = sessionQuery.operationError()

  const reload = () => sessionQuery.refetch()

  const sessionStore = useSessionStore()

  // Naming, tagging and transferring are for the agent of the session, also once it is over: the
  //   server refuses them to whoever only reads a session they found.
  const isOwnSession = computed(() => session.value?.user?.id === sessionStore.userId)

  const {
    runningSessions,
    ownRunningSessions,
    isLoaded: isAgentStateLoaded,
  } = storeToRefs(useChatAgentStore())

  // The state names the session before its conversation is loaded, and still when that failed; a
  //   found session that is a colleague's is among the running ones of the topics, or named once loaded.
  const namedSession = computed(
    () =>
      session.value ?? runningSessions.value.find((running) => running.id === toValue(sessionId)),
  )

  const name = computed(() => (namedSession.value ? chatSessionName(namedSession.value) : ''))

  const title = computed(() => (namedSession.value ? chatSessionTitle(namedSession.value) : ''))

  const ending = ref<ChatEnding>()

  // Over for good: nothing more is pushed for it.
  const isOver = computed(() => Boolean(ending.value) || session.value?.state === 'closed')

  const { reportMissedMessage } = useChatWindowPresence(sessionId, {
    windowElement,
    inputElement,
    isOver,
    focusWindow,
  })

  const entries = ref<ChatThreadEntry[]>([])

  const messageEntry = (message: ChatConversationMessage): ChatThreadEntry => ({
    kind: 'message',
    id: message.id,
    message,
  })

  const hasMessage = (id: string) =>
    entries.value.some((entry) => entry.kind === 'message' && entry.id === id)

  const messageTime = (message: ChatConversationMessage) => new Date(message.createdAt).getTime()

  // A message that was missed while the connection was down goes before what the agent sent meanwhile.
  const addMessage = (message: ChatConversationMessage) => {
    if (hasMessage(message.id)) return false

    const laterIndex = entries.value.findIndex(
      (entry) => entry.kind === 'message' && messageTime(entry.message) > messageTime(message),
    )

    if (laterIndex === -1) entries.value.push(messageEntry(message))
    else entries.value.splice(laterIndex, 0, messageEntry(message))

    return true
  }

  // What was pushed before the history arrived comes after it.
  let isHistoryLoaded = false

  watch(session, (value) => {
    if (!value) return

    if (isHistoryLoaded) {
      // A later result, e.g. after a reconnect, carries what was missed in between. The state,
      //   asked again at the same time, may answer later and still list a session that went elsewhere.
      const isStillTheirs = value.state === 'running' && value.user?.id === sessionStore.userId

      value.messages.forEach((message) => {
        if (addMessage(message) && isStillTheirs) reportMissedMessage(message)
      })
      return
    }

    isHistoryLoaded = true

    const loadedIds = new Set(value.messages.map((message) => message.id))

    entries.value = [
      ...value.messages.map(messageEntry),
      ...entries.value.filter((entry) => !loadedIds.has(entry.id)),
    ]
  })

  const isRunByAgent = computed(() =>
    ownRunningSessions.value.some((running) => running.id === toValue(sessionId)),
  )

  // The window opens for a session the agent runs. The state no longer listing it among theirs means
  //   it went elsewhere, e.g. a transfer in another tab or the old interface, and nothing is theirs to write.
  const hasBeenRunByAgent = ref(false)

  watch(
    isRunByAgent,
    (isRun) => {
      if (isRun) hasBeenRunByAgent.value = true
    },
    { immediate: true },
  )

  // A found session may be nobody's or a colleague's. The live state wins over the loaded session,
  //   stale after a change of hands that a reader gets no push about; it covers the agent's topics only.
  const liveSession = computed(() =>
    runningSessions.value.find((running) => running.id === toValue(sessionId)),
  )

  const runningAgent = computed(
    () =>
      (liveSession.value ?? (session.value?.state === 'running' ? session.value : undefined))?.user,
  )

  const isRunByColleague = computed(() =>
    Boolean(runningAgent.value && runningAgent.value.id !== sessionStore.userId),
  )

  // What the session pushes about its end comes later and tells more. Once a colleague runs it, the
  //   window reads like one of theirs the agent found.
  const isTransferred = computed(
    () =>
      hasBeenRunByAgent.value && !isRunByAgent.value && !isOver.value && !isRunByColleague.value,
  )

  const isClosed = computed(() => isOver.value || isTransferred.value)

  const isWaiting = computed(
    () =>
      !isClosed.value &&
      !isRunByAgent.value &&
      !liveSession.value &&
      session.value?.state === 'waiting',
  )

  const handlingAgent = computed(() =>
    session.value && !isClosed.value && isRunByColleague.value ? runningAgent.value : undefined,
  )

  const { clearUnreadMessages } = useChatUnreadMessagesStore()

  // What the agent did not read stays theirs once the conversation is over, but not once it went
  //   elsewhere, which only the session read again tells: the state drops one that ended as well.
  watch(
    () =>
      Boolean(handlingAgent.value) || (isTransferred.value && session.value?.state === 'waiting'),
    (isElsewhere) => {
      if (isElsewhere) clearUnreadMessages(toValue(sessionId))
    },
  )

  const canWrite = computed(
    () => Boolean(session.value) && !isClosed.value && !isWaiting.value && !handlingAgent.value,
  )

  // Theirs to end while they run it, loaded or not: without the conversation it is the one way out.
  const canEnd = computed(() => isRunByAgent.value && !isClosed.value)

  const isCustomerTyping = ref(false)

  const { start: hideTypingLater } = useTimeoutFn(
    () => {
      isCustomerTyping.value = false
    },
    TYPING_INDICATOR_MS,
    { immediate: false },
  )

  const updatesSubscription = new SubscriptionHandler(
    useChatSessionUpdatesSubscription({
      variables: { sessionId },
      // Search finds many sessions that are over; a transfer is presumed only, so its end still comes.
      enabled: () => !isOver.value,
    }),
    {
      // A reconnect subscribes again, which the server refuses for a session that went elsewhere or
      //   waits in a queue; the window already says so. Before the session is loaded, its query tells.
      errorCallback: (error) =>
        error.type !== GraphQLErrorTypes.Forbidden ||
        (Boolean(session.value) && !isTransferred.value && !isWaiting.value),
    },
  )

  updatesSubscription.onResult(({ data }) => {
    const update = data?.chatSessionUpdates

    if (!update) return

    if (update.message) {
      addMessage(update.message)
      isCustomerTyping.value = false
    }

    if (update.typing) {
      isCustomerTyping.value = true
      hideTypingLater()
    }

    if (update.notice) entries.value.push({ kind: 'notice', id: getUuid(), text: update.notice })

    if (update.leftBy)
      ending.value = { reason: 'left', name: update.leftBy, at: new Date().toISOString() }

    if (update.closedBy)
      ending.value = { reason: 'closed', name: update.closedBy, at: new Date().toISOString() }

    // A session in a queue pushes nothing: one loaded as waiting, or transferred away from the agent,
    //   has been taken since, maybe in a topic the live state does not cover.
    if (isWaiting.value || isTransferred.value) reload()
  })

  // Whoever takes the session, the agent or a colleague, what was loaded is stale, and the
  //   subscription, refused while the session waited in a queue, is over.
  watch(
    () => [isAgentStateLoaded.value, liveSession.value?.user?.id] as const,
    ([, agentId], [wasLoaded, previousAgentId]) => {
      // The first answer of the state is no change of hands.
      if (!wasLoaded || agentId === previousAgentId) return

      reload()

      if (agentId) updatesSubscription.restart()
    },
  )

  const messageMutation = new MutationHandler(useChatSessionMessageAddMutation())

  // The message comes back through the subscription as well, which the id keeps from doubling it.
  const sendMessage = async (content: string) => {
    // Who answers has read: a draft sent from an input that kept the focus reads nothing else.
    clearUnreadMessages(toValue(sessionId))

    const result = await messageMutation.send({ sessionId: toValue(sessionId), content })

    const message = result?.chatSessionMessageAdd?.message

    if (message) addMessage(message)

    return message
  }

  const typingMutation = new MutationHandler(useChatSessionTypingMutation(), {
    errorShowNotification: false,
  })

  // No trailing call: one pending after the agent sent the message would show them typing again.
  const sendTyping = useThrottleFn(
    () => typingMutation.send({ sessionId: toValue(sessionId) }).catch(() => undefined),
    TYPING_SIGNAL_INTERVAL_MS,
    false,
  )

  const endMutation = new MutationHandler(useChatSessionEndMutation())

  const application = useApplicationStore()

  const end = async () => {
    const result = await endMutation.send({ sessionId: toValue(sessionId) })

    const ended = result?.chatSessionEnd?.session
    const agent = ended?.user

    // The subscription tells it with the name the customer sees; this covers a slower one.
    ending.value ??= {
      reason: 'closed',
      name: agent ? formatChatAgentName(agent, application.config.user_name_format) : '',
      at: ended?.updatedAt ?? new Date().toISOString(),
    }
  }

  const isEnding = endMutation.loading()

  // Both come back with the session, which refreshes the title and the panel through the cache.
  const renameMutation = new MutationHandler(useChatSessionRenameMutation(), {
    errorNotificationMessage: __('The chat could not be renamed.'),
  })

  const rename = (name: string) => renameMutation.send({ sessionId: toValue(sessionId), name })

  const transferMutation = new MutationHandler(useChatSessionTransferMutation(), {
    errorNotificationMessage: __('The chat could not be transferred.'),
  })

  const transfer = (topicId: string) =>
    transferMutation.send({ sessionId: toValue(sessionId), topicId })

  return {
    session,
    name,
    title,
    isLoading,
    loadError,
    reload,
    entries,
    ending,
    isClosed,
    isTransferred,
    isRunByAgent,
    isOwnSession,
    isWaiting,
    handlingAgent,
    canWrite,
    canEnd,
    isCustomerTyping,
    isEnding,
    sendMessage,
    sendTyping,
    end,
    rename,
    transfer,
  }
}
