// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { setActivePinia, storeToRefs } from 'pinia'
import { computed, createApp, watch } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { initializeStore } from '#tests/support/components/initializeStore.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { nullableMock, waitForNextTick, waitUntil } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import type {
  ChatAgentAvailabilityUpdateMutation,
  ChatAgentStateQuery,
  ChatAgentStateUpdatesSubscription,
} from '#shared/graphql/types.ts'
import initializeApplicationStore, {
  pinia as applicationPinia,
  resetAndDisposeStores,
} from '#shared/stores/index.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import type { DeepPartial } from '#shared/types/utils.ts'
import emitter from '#shared/utils/emitter.ts'

import {
  agentState,
  chatSession,
  colleague,
  currentAgent,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  runningSession,
  salesTopic,
  supportTopic,
  waitingSessions,
} from '../../__tests__/mocks/chat-mocks.ts'
import { ChatAgentAvailabilityUpdateDocument } from '../../graphql/mutations/chatAgentAvailabilityUpdate.api.ts'
import {
  mockChatAgentAvailabilityUpdateMutation,
  mockChatAgentAvailabilityUpdateMutationError,
  waitForChatAgentAvailabilityUpdateMutationCalls,
} from '../../graphql/mutations/chatAgentAvailabilityUpdate.mocks.ts'
import { ChatAgentHeartbeatDocument } from '../../graphql/mutations/chatAgentHeartbeat.api.ts'
import { ChatAgentStateDocument } from '../../graphql/queries/chatAgentState.api.ts'
import {
  mockChatAgentStateQuery,
  waitForChatAgentStateQueryCalls,
} from '../../graphql/queries/chatAgentState.mocks.ts'
import { ChatAgentStateUpdatesDocument } from '../../graphql/subscriptions/chatAgentStateUpdates.api.ts'
import { getChatAgentStateUpdatesSubscriptionHandler } from '../../graphql/subscriptions/chatAgentStateUpdates.mocks.ts'
import { useChatAgentStore } from '../chatAgent.ts'

const waitForState = async () => {
  await waitForChatAgentStateQueryCalls()
  await waitForNextTick()
}

const pushState = (
  state: ChatAgentStateUpdatesSubscription['chatAgentStateUpdates']['agentState'],
) =>
  getChatAgentStateUpdatesSubscriptionHandler().trigger(
    nullableMock<ChatAgentStateUpdatesSubscription>({
      chatAgentStateUpdates: { __typename: 'ChatAgentStateUpdatesPayload', agentState: state },
    }),
  )

// The state and the getters as refs next to the actions, the way a component reads the store.
const useChatAgent = () => {
  const store = useChatAgentStore()

  return { ...storeToRefs(store), setAvailable: store.setAvailable }
}

// No component is rendered here, so the test's Pinia instance has no app. Only an installed one
//   tracks its stores, which the cleanup after each example then disposes.
beforeAll(() => {
  createApp({}).use(initializeStore())
})

describe('useChatAgentStore', () => {
  beforeEach(() => {
    mockChatAgent()
    mockChatEnabled()

    // Notifications outlive a test, so one example's would show up in the next.
    useNotifications().clearAllNotifications()
  })

  it('reads the queues, the sessions, the agents and the availability', async () => {
    mockAgentState({
      topics: [salesTopic, supportTopic],
      waitingQueues: [
        { topic: salesTopic, sessions: waitingSessions(2) },
        { topic: supportTopic, sessions: [chatSession(3)] },
      ],
      runningSessions: [runningSession(4, currentAgent), runningSession(5, colleague)],
      availableAgents: [currentAgent, colleague],
    })

    const {
      isLoaded,
      topics,
      waitingQueues,
      waitingCount,
      runningSessions,
      ownRunningSessions,
      availableAgents,
      isAvailable,
    } = useChatAgent()

    expect(isLoaded.value).toBe(false)

    await waitForState()

    expect(isLoaded.value).toBe(true)
    expect(topics.value.map((topic) => topic.name)).toEqual(['Sales', 'Support'])
    expect(waitingQueues.value.map((queue) => queue.sessions.length)).toEqual([2, 1])
    expect(waitingCount.value).toBe(3)
    expect(runningSessions.value.map((session) => session.internalId)).toEqual([4, 5])
    expect(ownRunningSessions.value.map((session) => session.internalId)).toEqual([4])
    expect(availableAgents.value.map((agent) => agent.fullname)).toEqual([
      'Chat Agent',
      'Other Agent',
    ])
    expect(isAvailable.value).toBe(true)
  })

  it('does not query while the chat feature is off', async () => {
    mockChatEnabled(false)

    const { isEnabled, isLoaded, waitingCount } = useChatAgent()

    await waitForNextTick()

    expect(isEnabled.value).toBe(false)
    expect(isLoaded.value).toBe(false)
    expect(waitingCount.value).toBe(0)
    expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(0)
    expect(getChatAgentStateUpdatesSubscriptionHandler()).toBeUndefined()
  })

  it('does not query without the chat permission', async () => {
    mockPermissions(['ticket.agent'])

    const { isLoaded, waitingCount } = useChatAgent()

    await waitForNextTick()

    expect(isLoaded.value).toBe(false)
    expect(waitingCount.value).toBe(0)
    expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(0)
    expect(getChatAgentStateUpdatesSubscriptionHandler()).toBeUndefined()
  })

  it('shares one query, one subscription and one heartbeat between its consumers', async () => {
    mockAgentState({
      active: true,
      waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(2) }],
    })

    const first = useChatAgentStore()
    const second = useChatAgentStore()

    await waitForState()
    await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length > 0)

    expect(second).toBe(first)
    expect(second.waitingCount).toBe(2)
    expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(1)
    expect(getGraphQLMockCalls(ChatAgentStateUpdatesDocument)).toHaveLength(1)
    expect(getGraphQLMockCalls(ChatAgentHeartbeatDocument)).toHaveLength(1)
  })

  it('queries again after a reconnect', async () => {
    mockAgentState()

    useChatAgent()

    await waitForChatAgentStateQueryCalls()

    emitter.emit('reconnected')

    await waitUntil(() => getGraphQLMockCalls(ChatAgentStateDocument).length === 2)
  })

  it('applies a pushed state without querying again', async () => {
    mockAgentState({ active: false })

    const { waitingCount, runningSessions, isAvailable } = useChatAgent()

    await waitForState()

    expect(waitingCount.value).toBe(0)
    expect(isAvailable.value).toBe(false)

    await pushState(
      agentState({
        active: true,
        waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(2) }],
        runningSessions: [runningSession(3, colleague)],
      }),
    )
    await waitForNextTick()

    expect(waitingCount.value).toBe(2)
    expect(runningSessions.value.map((session) => session.internalId)).toEqual([3])
    expect(isAvailable.value).toBe(true)
    expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(1)
  })

  it('keeps the loaded state while the subscription carries no payload', async () => {
    mockAgentState({ waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(2) }] })

    const { waitingCount } = useChatAgent()

    await waitForState()

    await pushState(null)
    await waitForNextTick()

    expect(waitingCount.value).toBe(2)
  })

  describe('availability', () => {
    it('writes the toggle and reads the state again', async () => {
      mockAgentState({ active: false })
      mockChatAgentAvailabilityUpdateMutation({
        chatAgentAvailabilityUpdate: { active: true, errors: null },
      })

      const { isAvailable, setAvailable } = useChatAgent()

      await waitForState()

      expect(isAvailable.value).toBe(false)

      const pending = setAvailable(true)

      await waitForNextTick()

      expect(isAvailable.value).toBe(true)

      const calls = await waitForChatAgentAvailabilityUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ active: true })

      expect(await pending).toBe(true)
      expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(2)
    })

    // The agent clicks twice within one round trip, and the server answers the later write with
    //   the state of the earlier one, e.g. because it committed the two in the other order.
    it('keeps the switch where the agent put it last, and ends with what the query answers', async () => {
      mockAgentState({ active: true })

      const answers: ((result: DeepPartial<ChatAgentAvailabilityUpdateMutation>) => void)[] = []

      mockChatAgentAvailabilityUpdateMutation(
        () =>
          new Promise((resolve) => {
            answers.push(resolve)
          }),
      )

      const { isAvailable, setAvailable } = useChatAgent()

      await waitForState()

      const off = setAvailable(false)
      const on = setAvailable(true)

      await waitUntil(() => answers.length === 2)

      expect(isAvailable.value).toBe(true)

      answers[0]({ chatAgentAvailabilityUpdate: { active: false, errors: null } })

      expect(await off).toBe(true)
      expect(isAvailable.value).toBe(true)

      answers[1]({ chatAgentAvailabilityUpdate: { active: false, errors: null } })

      expect(await on).toBe(true)
      expect(isAvailable.value).toBe(true)
      expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(3)
    })

    // The later write answers first, and the query fails after the earlier one answered last, so nothing
    //   but the write itself could put the switch back.
    it('keeps the switch where the agent put it last when the earlier write answers last', async () => {
      let isQueryFailing = false

      mockChatAgentStateQuery(() =>
        isQueryFailing
          ? Promise.reject(new Error('Network error'))
          : { chatAgentState: agentState({ active: false }) },
      )

      const answers: ((result: DeepPartial<ChatAgentAvailabilityUpdateMutation>) => void)[] = []

      mockChatAgentAvailabilityUpdateMutation(
        () =>
          new Promise((resolve) => {
            answers.push(resolve)
          }),
      )

      const { isAvailable, setAvailable } = useChatAgent()

      await waitForState()

      const on = setAvailable(true)
      const off = setAvailable(false)

      await waitUntil(() => answers.length === 2)

      answers[1]({ chatAgentAvailabilityUpdate: { active: false, errors: null } })

      expect(await off).toBe(true)
      expect(isAvailable.value).toBe(false)

      isQueryFailing = true

      answers[0]({ chatAgentAvailabilityUpdate: { active: true, errors: null } })

      await on

      expect(isAvailable.value).toBe(false)
    })

    it('puts the switch back and reports a failed write', async () => {
      mockAgentState({ active: false })
      mockChatAgentAvailabilityUpdateMutationError('Something went wrong', {
        type: GraphQLErrorTypes.UnknownError,
      })

      const { isAvailable, setAvailable } = useChatAgent()

      await waitForState()

      expect(await setAvailable(true)).toBe(false)

      expect(isAvailable.value).toBe(false)
      expect(useNotifications().notifications.value).toEqual([
        expect.objectContaining({ message: 'The chat availability could not be updated.' }),
      ])
    })

    it('refuses to switch on without a selected topic among several', async () => {
      mockChatAgent({ selectedTopics: [] })

      mockAgentState({ active: false, topics: [salesTopic, supportTopic] })

      const { isAvailable, setAvailable } = useChatAgent()

      await waitForState()

      expect(await setAvailable(true)).toBe(false)

      expect(isAvailable.value).toBe(false)
      expect(getGraphQLMockCalls(ChatAgentAvailabilityUpdateDocument)).toHaveLength(0)
      expect(useNotifications().notifications.value).toEqual([])
    })

    it('refuses to switch on without a selected topic when there is none to select', async () => {
      mockChatAgent({ selectedTopics: [] })

      mockAgentState({ active: false, topics: [] })

      const { isAvailable, setAvailable } = useChatAgent()

      await waitForState()

      await setAvailable(true)

      expect(isAvailable.value).toBe(false)
      expect(getGraphQLMockCalls(ChatAgentAvailabilityUpdateDocument)).toHaveLength(0)
    })

    it('switches on without a selected topic when there is a single one, which the server takes', async () => {
      mockChatAgent({ selectedTopics: [] })

      mockAgentState({ active: false, topics: [supportTopic] })
      mockChatAgentAvailabilityUpdateMutation({
        chatAgentAvailabilityUpdate: { active: true, errors: null },
      })

      const { setAvailable } = useChatAgent()

      await waitForState()

      await setAvailable(true)

      const availabilityCalls = await waitForChatAgentAvailabilityUpdateMutationCalls()

      expect(availabilityCalls.at(-1)?.variables).toEqual({ active: true })
      expect(useNotifications().notifications.value).toEqual([])
    })

    it('does not write the availability the agent already has', async () => {
      mockAgentState({ active: true })

      const { setAvailable } = useChatAgent()

      await waitForState()

      expect(await setAvailable(true)).toBe(true)

      expect(getGraphQLMockCalls(ChatAgentAvailabilityUpdateDocument)).toHaveLength(0)
    })

    it('switches off without a selected topic', async () => {
      mockChatAgent({ selectedTopics: [] })

      mockAgentState({ active: true })
      mockChatAgentAvailabilityUpdateMutation({
        chatAgentAvailabilityUpdate: { active: false, errors: null },
      })

      const { setAvailable } = useChatAgent()

      await waitForState()

      await setAvailable(false)

      const calls = await waitForChatAgentAvailabilityUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ active: false })
    })
  })

  describe('heartbeat', () => {
    beforeEach(() => {
      vi.useFakeTimers({ shouldAdvanceTime: true })
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('beats once the agent is available, and every 55 seconds after that', async () => {
      mockAgentState({ active: true })

      useChatAgent()

      await waitForState()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 1)

      await vi.advanceTimersByTimeAsync(55 * 1000)

      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 2)
    })

    it('does not beat while the agent is unavailable', async () => {
      mockAgentState({ active: false })

      useChatAgent()

      await waitForState()

      await vi.advanceTimersByTimeAsync(55 * 1000)

      expect(getGraphQLMockCalls(ChatAgentHeartbeatDocument)).toHaveLength(0)
    })

    it('reads the state again with every beat after the first', async () => {
      mockAgentState({ active: true })

      useChatAgent()

      await waitForState()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 1)

      expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(1)

      await vi.advanceTimersByTimeAsync(55 * 1000)

      await waitUntil(() => getGraphQLMockCalls(ChatAgentStateDocument).length === 2)
    })

    // The read answers over HTTP and the push comes over the websocket, so the push of a chat the agent
    //   accepted can come in before the answer of a read that started earlier.
    it('keeps a state pushed while a beat reads it, and reads the state again', async () => {
      const waiting = agentState({
        waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(1) }],
      })
      const accepted = agentState({ runningSessions: [runningSession(1, currentAgent)] })

      let reads = 0
      let answerBeat: ((result: DeepPartial<ChatAgentStateQuery>) => void) | undefined

      mockChatAgentStateQuery(() => {
        reads += 1

        if (reads === 2) {
          return new Promise((resolve) => {
            answerBeat = resolve
          })
        }

        return { chatAgentState: reads === 1 ? waiting : accepted }
      })

      const { ownRunningSessions } = useChatAgent()

      const hasAccepted = computed(() => ownRunningSessions.value.length > 0)
      const shown: boolean[] = []

      watch(hasAccepted, (value) => shown.push(value), { flush: 'sync' })

      await waitForState()

      await vi.advanceTimersByTimeAsync(55 * 1000)
      await waitUntil(() => answerBeat !== undefined)

      await pushState(accepted)

      answerBeat!({ chatAgentState: waiting })

      await waitUntil(() => reads === 3)
      await waitUntil(() => hasAccepted.value)

      expect(shown).toEqual([true])
    })

    // Like in the old UI, which reads the state again only while the agent is available.
    it('does not read the state again while the agent is unavailable', async () => {
      mockAgentState({ active: false })

      useChatAgent()

      await waitForState()

      await vi.advanceTimersByTimeAsync(55 * 1000)

      expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(1)
    })

    it('stops beating once the agent switched off', async () => {
      mockAgentState({ active: true })
      mockChatAgentAvailabilityUpdateMutation({
        chatAgentAvailabilityUpdate: { active: false, errors: null },
      })

      const { setAvailable } = useChatAgent()

      await waitForState()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 1)

      mockAgentState({ active: false })

      await setAvailable(false)

      await vi.advanceTimersByTimeAsync(2 * 55 * 1000)

      expect(getGraphQLMockCalls(ChatAgentHeartbeatDocument)).toHaveLength(1)
    })

    // Unlike in the old UI, no websocket client keeps the session of the agent alive.
    it('keeps beating after switching off while a conversation of the agent is running', async () => {
      const conversation = [runningSession(1, currentAgent)]

      mockAgentState({ active: true, runningSessions: conversation })
      mockChatAgentAvailabilityUpdateMutation({
        chatAgentAvailabilityUpdate: { active: false, errors: null },
      })

      const { setAvailable } = useChatAgent()

      await waitForState()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 1)

      mockAgentState({ active: false, runningSessions: conversation })

      await setAvailable(false)

      await vi.advanceTimersByTimeAsync(55 * 1000)

      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 2)
    })

    it('beats for a running conversation of an agent who is unavailable', async () => {
      mockAgentState({ active: false, runningSessions: [runningSession(1, currentAgent)] })

      useChatAgent()

      await waitForState()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 1)
    })
  })

  // The logout disposes the stores of the session through the registry of the application's own
  //   Pinia instance, which the test setup does not use.
  describe('with the session', () => {
    beforeAll(() => {
      initializeApplicationStore(createApp({}))
    })

    beforeEach(() => {
      setActivePinia(applicationPinia)
      mockChatAgent()
      mockChatEnabled()

      vi.useFakeTimers({ shouldAdvanceTime: true })
    })

    afterEach(() => {
      vi.useRealTimers()

      resetAndDisposeStores()
      setActivePinia(initializeStore())
    })

    it('ends the heartbeat, the subscription and the reads with the session', async () => {
      mockAgentState({ active: true })

      useChatAgentStore()

      await waitForState()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 1)

      resetAndDisposeStores(true)

      emitter.emit('reconnected')

      await vi.advanceTimersByTimeAsync(2 * 55 * 1000)

      expect(getGraphQLMockCalls(ChatAgentHeartbeatDocument)).toHaveLength(1)
      expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(1)
      expect(getChatAgentStateUpdatesSubscriptionHandler().closed()).toBe(true)
    })

    it('starts over in the next session', async () => {
      mockAgentState({
        active: true,
        waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(2) }],
      })

      const first = useChatAgentStore()

      await waitForState()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 1)

      resetAndDisposeStores(true)

      mockAgentState({ active: true })

      const second = useChatAgentStore()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentStateDocument).length === 2)
      await waitUntil(() => getGraphQLMockCalls(ChatAgentHeartbeatDocument).length === 2)
      await waitForNextTick()

      expect(second).not.toBe(first)
      expect(second.waitingCount).toBe(0)
      expect(getGraphQLMockCalls(ChatAgentStateUpdatesDocument)).toHaveLength(2)
      expect(getChatAgentStateUpdatesSubscriptionHandler().closed()).toBe(false)
    })
  })
})
