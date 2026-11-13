// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useIntervalFn } from '@vueuse/core'
import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, nextTick, ref, watch } from 'vue'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import type {
  ChatAgentStateQuery,
  ChatAgentStateUpdatesSubscription,
  ChatAgentStateUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useChatAccess } from '#desktop/entities/chat/composables/useChatAccess.ts'
import { useChatAgentAvailabilityUpdateMutation } from '#desktop/entities/chat/graphql/mutations/chatAgentAvailabilityUpdate.api.ts'
import { useChatAgentHeartbeatMutation } from '#desktop/entities/chat/graphql/mutations/chatAgentHeartbeat.api.ts'
import { useChatAgentStateQuery } from '#desktop/entities/chat/graphql/queries/chatAgentState.api.ts'
import { ChatAgentStateUpdatesDocument } from '#desktop/entities/chat/graphql/subscriptions/chatAgentStateUpdates.api.ts'

// The old UI's status poll interval: an agent counts as present for two minutes after their last beat.
const HEARTBEAT_INTERVAL_MS = 55 * 1000

// What the server says about the agent's chat, and the heartbeat that keeps them present in it. A
//   store, so every screen reads one query, and so both end with the session.
export const useChatAgentStore = defineStore('chatAgent', () => {
  const session = useSessionStore()

  const { isChatEnabled } = useChatAccess()

  // The navigation entry is part of every page, also for users who never chat, so the
  //   query waits for the setting and the permission.
  const isEnabled = computed(() => isChatEnabled.value && session.hasPermission('chat.agent'))

  const stateQuery = new QueryHandler(
    useChatAgentStateQuery({
      enabled: isEnabled,
      fetchPolicy: 'cache-and-network',
    }),
  )

  // A read answers over HTTP and a push comes over the websocket, so a push can overtake the answer of
  //   a read that saw an older state, and Apollo keeps whichever comes last. A push that comes while a
  //   read is on its way is left out, and the state is read again once the reads are done.
  let readsInFlight = 0
  let isPushLeftOut = false

  // The subscription pushes the same shape the query answers with, so a push replaces the result as
  //   a whole; it starts without a payload.
  stateQuery.subscribeToMore<
    ChatAgentStateUpdatesSubscriptionVariables,
    ChatAgentStateUpdatesSubscription
  >({
    document: ChatAgentStateUpdatesDocument,
    updateQuery: (previous, { subscriptionData }) => {
      const pushedState = subscriptionData.data?.chatAgentStateUpdates.agentState

      if (!pushedState) return null as unknown as ChatAgentStateQuery

      if (readsInFlight > 0) {
        isPushLeftOut = true
        return null as unknown as ChatAgentStateQuery
      }

      return { chatAgentState: pushedState }
    },
  })

  const stateResult = stateQuery.result()

  // A result left behind by a disabled query, e.g. once the chat is switched off, does not count.
  const isLoaded = computed(() => isEnabled.value && stateResult.value !== undefined)

  const agentState = computed(() =>
    isEnabled.value ? stateResult.value?.chatAgentState : undefined,
  )

  const topics = computed(() => agentState.value?.topics ?? [])

  const waitingQueues = computed(() => agentState.value?.waitingQueues ?? [])

  const waitingCount = computed(() =>
    waitingQueues.value.reduce((count, queue) => count + queue.sessions.length, 0),
  )

  // Every session in progress in the agent's topics; the agent's own ones are their windows.
  const runningSessions = computed(() => agentState.value?.runningSessions ?? [])

  const ownRunningSessions = computed(() =>
    runningSessions.value.filter((chatSession) => chatSession.user?.id === session.userId),
  )

  const availableAgents = computed(() => agentState.value?.availableAgents ?? [])

  // The topics switched on in the agent's chat preferences, the same key the old UI writes.
  const hasSelectedTopic = computed(() =>
    Object.values(session.user?.preferences?.chat?.active ?? {}).includes('on'),
  )

  // Shown while the toggle's write is in flight, so the switch follows the click.
  const pendingAvailability = ref<boolean>()

  // What the write stored, shown until the state carries it or the query answered after the write.
  const storedAvailability = ref<boolean>()

  const isAvailable = computed(
    () =>
      pendingAvailability.value ?? storedAvailability.value ?? Boolean(agentState.value?.active),
  )

  watch(
    () => agentState.value?.active,
    () => {
      storedAvailability.value = undefined
    },
  )

  const availabilityMutation = new MutationHandler(useChatAgentAvailabilityUpdateMutation(), {
    errorNotificationMessage: __('The chat availability could not be updated.'),
  })

  const refetch = async (): ReturnType<typeof stateQuery.refetch> => {
    readsInFlight += 1

    const result = await stateQuery.refetch().finally(() => {
      readsInFlight -= 1
    })

    if (readsInFlight > 0 || !isPushLeftOut) return result

    isPushLeftOut = false

    // After a failed read, the next beat or push brings the state; reading again at once would repeat
    //   a failing read with every push.
    return result.data ? refetch() : result
  }

  // Not the handler's own reconnect option, whose read would not hold a push back.
  useOnEmitter('reconnected', () => refetch())

  // Counted, so that only the latest write moves the switch: an earlier one may end or answer after it.
  let latestWrite = 0

  // Resolves with whether the agent has the availability now, as far as the client knows.
  const setAvailable = async (active: boolean) => {
    // The switch also reports a value it was given: a state loaded or pushed after a change in the
    //   old UI. Writing it back would overwrite what the agent did there in the meantime.
    if (active === isAvailable.value) return true

    const write = ++latestWrite

    pendingAvailability.value = active

    // No availability without a topic to handle, unless there is a single one, which the server takes when
    //   switching on. The switch says why and is marked disabled, so it is turned down without a word, like
    //   a disabled menu item; it snaps back once the pending value cycles through.
    if (active && !hasSelectedTopic.value && topics.value.length !== 1) {
      await nextTick()
      if (write === latestWrite) pendingAvailability.value = undefined
      return false
    }

    try {
      const result = await availabilityMutation.send({ active })

      if (write === latestWrite) {
        storedAvailability.value = result?.chatAgentAvailabilityUpdate?.active ?? active
      }

      // The push this write causes would do as well, but the switch should not wait for it. What the
      //   query answers is the truth, also when it is what the state held before.
      const { data } = await refetch()

      if (data) storedAvailability.value = undefined

      return true
    } catch {
      // The handler already notified.
      return false
    } finally {
      if (write === latestWrite) pendingAvailability.value = undefined
    }
  }

  const heartbeatMutation = new MutationHandler(useChatAgentHeartbeatMutation(), {
    errorShowNotification: false,
  })

  const sendHeartbeat = () => heartbeatMutation.send().catch(() => undefined)

  const { resume: startHeartbeat, pause: stopHeartbeat } = useIntervalFn(
    () => {
      sendHeartbeat()

      // Nothing is pushed when an agent changes topics or leaves without switching off, so the state is
      //   read again with every beat, like the old UI does.
      refetch()
    },
    HEARTBEAT_INTERVAL_MS,
    { immediate: false },
  )

  // The beat counts the agent and their sessions as present, which no websocket client does for the new
  //   UI, so it goes on after switching off while a conversation of theirs is running.
  const needsHeartbeat = computed(
    () =>
      isEnabled.value && (Boolean(agentState.value?.active) || ownRunningSessions.value.length > 0),
  )

  watch(
    needsHeartbeat,
    (isNeeded) => {
      if (!isNeeded) {
        stopHeartbeat()
        return
      }

      sendHeartbeat()
      startHeartbeat()
    },
    { immediate: true },
  )

  return {
    isEnabled,
    isLoaded,
    topics,
    waitingQueues,
    waitingCount,
    runningSessions,
    ownRunningSessions,
    availableAgents,
    hasSelectedTopic,
    isAvailable,
    setAvailable,
    refetch,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useChatAgentStore, import.meta.hot))
}
