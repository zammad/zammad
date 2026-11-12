// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getActivePinia } from 'pinia'
import { defineComponent, h } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useSessionStore } from '#shared/stores/session.ts'

import {
  disposeSessionStores,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  mockChatPreferences,
} from '../../__tests__/mocks/chat-mocks.ts'
import { ChatAgentStateDocument } from '../../graphql/queries/chatAgentState.api.ts'
import { waitForChatAgentStateQueryCalls } from '../../graphql/queries/chatAgentState.mocks.ts'
import { useChatAgentStore } from '../../stores/chatAgent.ts'
import { useChatAnnouncementsStore } from '../../stores/chatAnnouncements.ts'
import { useChatNotificationsStore } from '../../stores/chatNotifications.ts'
import { useChatPreferencesStore } from '../../stores/chatPreferences.ts'
import { useChatUnreadMessagesStore } from '../../stores/chatUnreadMessages.ts'
import { useChatSessionStores } from '../useChatSessionStores.ts'

import type { RouteRecordRaw } from 'vue-router'

const routerRoutes: RouteRecordRaw[] = [
  { path: '/', name: 'Dashboard', component: { template: 'dashboard' } },
  { path: '/chat', name: 'Chat', component: { template: 'chat' } },
]

// The app root, which lives through every session of the tab.
const Host = defineComponent({
  setup() {
    useChatSessionStores()

    return () => h('div')
  },
})

const renderHost = () => renderComponent(Host, { router: true, routerRoutes, store: true })

const SESSION_STORES = ['chatAnnouncements', 'chatNotifications']

const createdSessionStores = () =>
  SESSION_STORES.filter((id) => id in (getActivePinia()?.state.value ?? {}))

const startSession = async (id: string) => {
  useSessionStore().id = id

  await waitForNextTick()
}

// What the logout does: the stores of the session end, then the session is reset.
const endSession = async () => {
  disposeSessionStores(
    useChatAnnouncementsStore(),
    useChatNotificationsStore(),
    useChatUnreadMessagesStore(),
    useChatPreferencesStore(),
    useChatAgentStore(),
  )

  useSessionStore().id = null

  await waitForNextTick()
}

describe('useChatSessionStores', () => {
  beforeEach(() => {
    mockChatAgent()
    mockChatEnabled()
    mockAgentState()
    mockChatPreferences()

    // The session store is created before a component installs the test's Pinia instance, which
    //   only then tracks its stores: the cleanup after an example does not reach it.
    Object.assign(useSessionStore(), { id: null, initialized: false })
  })

  it('creates no store without a session', async () => {
    renderHost()

    await waitForNextTick()

    expect(createdSessionStores()).toEqual([])
  })

  it('creates the stores for the session the tab starts with', async () => {
    useSessionStore().id = 'session-1'

    renderHost()

    expect(createdSessionStores()).toEqual(SESSION_STORES)
  })

  // The login of another tab sets the session, and nothing else.
  it('creates the stores for a session taken over from another tab', async () => {
    renderHost()

    await startSession('session-1')

    expect(useSessionStore().initialized).toBe(false)
    expect(createdSessionStores()).toEqual(SESSION_STORES)
  })

  // A login sets the id first and loads the user after it.
  it('reads the chat once the user of the session is loaded', async () => {
    useSessionStore().user = null

    renderHost()

    await startSession('session-1')

    expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(0)

    mockChatAgent()

    await waitForChatAgentStateQueryCalls()

    expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(1)
  })

  it('creates the stores again for the next session', async () => {
    useSessionStore().id = 'session-1'

    renderHost()

    await endSession()

    expect(createdSessionStores()).toEqual([])

    await startSession('session-2')

    expect(createdSessionStores()).toEqual(SESSION_STORES)
  })

  // A logout that fails to load the settings anew leaves the session initialized.
  it('creates the stores again after a logout that left the session initialized', async () => {
    const session = useSessionStore()

    session.id = 'session-1'
    session.initialized = true

    renderHost()

    await endSession()
    await startSession('session-2')

    expect(session.initialized).toBe(true)
    expect(createdSessionStores()).toEqual(SESSION_STORES)
  })
})
