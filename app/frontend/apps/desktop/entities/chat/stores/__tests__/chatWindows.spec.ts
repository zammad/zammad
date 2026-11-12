// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { createApp } from 'vue'

import { initializeStore } from '#tests/support/components/initializeStore.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import type { ChatAgentStateUpdatesSubscription } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  agentState,
  colleague,
  currentAgent,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  runningSession,
} from '../../__tests__/mocks/chat-mocks.ts'
import { waitForChatAgentStateQueryCalls } from '../../graphql/queries/chatAgentState.mocks.ts'
import { getChatAgentStateUpdatesSubscriptionHandler } from '../../graphql/subscriptions/chatAgentStateUpdates.mocks.ts'
import { useChatWindowsStore } from '../chatWindows.ts'

const sessionId = (internalId: number) => convertToGraphQLId('Chat::Session', internalId)

const waitForState = async () => {
  await waitForChatAgentStateQueryCalls()
  await waitForNextTick()
}

// No component is rendered here, so the test's Pinia instance has no app. Only an installed one
//   tracks its stores, which the cleanup after each example then disposes.
beforeAll(() => {
  createApp({}).use(initializeStore())
})

describe('useChatWindowsStore', () => {
  beforeEach(() => {
    mockChatAgent()
    mockChatEnabled()
  })

  const setup = async () => {
    const store = useChatWindowsStore()

    await waitForState()

    return store
  }

  it('opens a window for every running conversation of the agent, and no other', async () => {
    mockAgentState({
      runningSessions: [runningSession(1, currentAgent), runningSession(2, colleague)],
    })

    const { sessionIds } = storeToRefs(await setup())

    expect(sessionIds.value).toEqual([sessionId(1)])
  })

  it('opens a window for a conversation the agent takes later', async () => {
    mockAgentState({ runningSessions: [runningSession(1, currentAgent)] })

    const { sessionIds } = storeToRefs(await setup())

    await getChatAgentStateUpdatesSubscriptionHandler().trigger(
      nullableMock<ChatAgentStateUpdatesSubscription>({
        chatAgentStateUpdates: {
          __typename: 'ChatAgentStateUpdatesPayload',
          agentState: agentState({
            runningSessions: [runningSession(1, currentAgent), runningSession(2, currentAgent)],
          }),
        },
      }),
    )
    await waitForNextTick()

    expect(sessionIds.value).toEqual([sessionId(1), sessionId(2)])
  })

  // A session found through search, whoever runs it; the route opens it before the page is mounted,
  //   and the agent's own conversations are there as well by then.
  it('keeps a window opened before the state is loaded next to the running conversations', async () => {
    mockAgentState({ runningSessions: [runningSession(1, currentAgent)] })

    const store = useChatWindowsStore()

    store.openWindow(sessionId(2))
    store.windowToReveal = sessionId(2)

    await waitForState()

    expect(store.sessionIds).toEqual([sessionId(2), sessionId(1)])
    expect(store.windowToReveal).toBe(sessionId(2))
  })

  it('opens a window for any session once', async () => {
    mockAgentState({ runningSessions: [runningSession(1, currentAgent)] })

    const store = await setup()

    store.openWindow(sessionId(2))
    store.openWindow(sessionId(2))
    store.openWindow(sessionId(1))

    expect(store.sessionIds).toEqual([sessionId(1), sessionId(2)])
  })

  it('closes a window without touching the others', async () => {
    mockAgentState({ runningSessions: [runningSession(1, currentAgent)] })

    const store = await setup()

    store.openWindow(sessionId(2))
    store.closeWindow(sessionId(1))

    expect(store.sessionIds).toEqual([sessionId(2)])
  })
})
