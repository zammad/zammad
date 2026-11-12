// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, h } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { resetGlobalStates } from '#tests/support/mock-globalState.ts'
import {
  holdLockFromAnotherTab,
  mockWebLocks,
  unmockWebLocks,
} from '#tests/support/mock-webLocks.ts'
import { nullableMock, waitForNextTick, waitUntil } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import type { ChatAgentStateUpdatesSubscription } from '#shared/graphql/types.ts'

import { BROWSER_NOTIFICATION_LOCK } from '#desktop/composables/useBrowserNotification.ts'

import {
  agentState,
  currentAgent,
  disposeSessionStores,
  mockAgentState,
  mockChatAgent,
  mockChatPreferences,
  runningSession,
  supportTopic,
  waitingSessions,
} from '../../__tests__/mocks/chat-mocks.ts'
import { ChatAgentAvailabilityUpdateDocument } from '../../graphql/mutations/chatAgentAvailabilityUpdate.api.ts'
import { mockChatAgentAvailabilityUpdateMutation } from '../../graphql/mutations/chatAgentAvailabilityUpdate.mocks.ts'
import { ChatAgentStateDocument } from '../../graphql/queries/chatAgentState.api.ts'
import { waitForChatAgentStateQueryCalls } from '../../graphql/queries/chatAgentState.mocks.ts'
import { ChatPreferencesDocument } from '../../graphql/queries/chatPreferences.api.ts'
import { waitForChatPreferencesQueryCalls } from '../../graphql/queries/chatPreferences.mocks.ts'
import { getChatAgentStateUpdatesSubscriptionHandler } from '../../graphql/subscriptions/chatAgentStateUpdates.mocks.ts'
import { useChatAgentStore } from '../chatAgent.ts'
import { useChatAnnouncementsStore } from '../chatAnnouncements.ts'
import { useChatPreferencesStore } from '../chatPreferences.ts'

import type { RouteRecordRaw } from 'vue-router'

// The shared browser notification instance snapshots the permission when it is
//   created, so every example gets a fresh one.
vi.mock('@vueuse/core', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@vueuse/core')>()),
  createGlobalState: (await import('#tests/support/mock-globalState.ts')).createGlobalState,
}))

const IDLE_TIMEOUT_SECONDS = 30

// What the setting falls back to when it holds nothing usable.
const DEFAULT_IDLE_TIMEOUT_SECONDS = 120

const routerRoutes: RouteRecordRaw[] = [
  { path: '/', name: 'Dashboard', component: { template: 'dashboard' } },
  { path: '/chat', name: 'Chat', component: { template: 'chat' } },
  { path: '/:pathMatch(.*)*', name: 'Error', component: { template: 'error' } },
]

// The app root creates it with the session; a component does so here.
const Host = defineComponent({
  setup() {
    useChatAnnouncementsStore()

    return () => h('div')
  },
})

// Records what the notifier creates; the global stub of the test setup drops the arguments.
class NotificationStub {
  static permission: NotificationPermission = 'granted'

  static requestPermission = () => Promise.resolve('granted' as NotificationPermission)

  static instances: NotificationStub[] = []

  close = vi.fn()

  onclick: (() => void) | null = null

  constructor(
    public title: string,
    public options?: NotificationOptions,
  ) {
    // VueUse probes the support with an empty notification.
    if (title) NotificationStub.instances.push(this)
  }
}

// Counts the plays of the announcement sound.
class AudioStub {
  static instances: AudioStub[] = []

  preload = ''

  currentTime = 0

  play = vi.fn(() => Promise.resolve())

  constructor(public src: string) {
    AudioStub.instances.push(this)
  }
}

const soundsPlayed = () =>
  AudioStub.instances.reduce((sum, audio) => sum + audio.play.mock.calls.length, 0)

const waiting = (count: number) => [{ topic: supportTopic, sessions: waitingSessions(count) }]

const pushState = async (overrides: Parameters<typeof agentState>[0]) => {
  await getChatAgentStateUpdatesSubscriptionHandler().trigger(
    nullableMock<ChatAgentStateUpdatesSubscription>({
      chatAgentStateUpdates: {
        __typename: 'ChatAgentStateUpdatesPayload',
        agentState: agentState(overrides),
      },
    }),
  )
  await waitForNextTick()
}

const setWindowFocus = (focused: boolean) => {
  vi.spyOn(document, 'hasFocus').mockReturnValue(focused)
}

const renderHost = async (overrides: Parameters<typeof agentState>[0] = {}) => {
  mockAgentState({ active: true, waitingQueues: waiting(0), ...overrides })

  const view = renderComponent(Host, { router: true, routerRoutes, store: true })

  await waitForChatAgentStateQueryCalls()
  await waitForChatPreferencesQueryCalls()
  await waitForNextTick()

  return view
}

const availabilityWrites = () => getGraphQLMockCalls(ChatAgentAvailabilityUpdateDocument)

// The user and the settings stay, so nothing but the end of the stores stops what they do.
const endSession = () =>
  disposeSessionStores(useChatAnnouncementsStore(), useChatPreferencesStore(), useChatAgentStore())

describe('useChatAnnouncementsStore', () => {
  beforeEach(() => {
    resetGlobalStates()
    vi.stubGlobal('Notification', NotificationStub)
    vi.stubGlobal('Audio', AudioStub)
    NotificationStub.permission = 'granted'
    NotificationStub.instances = []
    AudioStub.instances = []

    setWindowFocus(false)
    mockChatAgent()
    mockChatPreferences()
    mockApplicationConfig({ chat: true, chat_agent_idle_timeout: String(IDLE_TIMEOUT_SECONDS) })

    // Notices outlive an example, so one example's would show up in the next.
    useNotifications().clearAllNotifications()
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.useRealTimers()
    unmockWebLocks()
  })

  describe('announcing a waiting customer', () => {
    it('plays the sound and shows a silent notification with the count once the number rises', async () => {
      await renderHost({ waitingQueues: waiting(1) })

      await pushState({ active: true, waitingQueues: waiting(3) })

      expect(soundsPlayed()).toBe(1)
      expect(AudioStub.instances[0].src).toBe('/assets/sounds/chat_new.mp3')
      expect(NotificationStub.instances).toHaveLength(1)
      expect(NotificationStub.instances[0].title).toBe('3 waiting customers')
      expect(NotificationStub.instances[0].options).toMatchObject({
        silent: true,
        tag: 'chat-waiting-customers',
      })
    })

    it('says "waiting customer" for the first one', async () => {
      await renderHost()

      await pushState({ active: true, waitingQueues: waiting(1) })

      expect(NotificationStub.instances[0].title).toBe('1 waiting customer')
    })

    it('stays quiet about the customers waiting in the first result', async () => {
      await renderHost({ waitingQueues: waiting(2) })

      expect(soundsPlayed()).toBe(0)
      expect(NotificationStub.instances).toHaveLength(0)
    })

    it('stays quiet while the number falls or stays', async () => {
      await renderHost({ waitingQueues: waiting(3) })

      await pushState({ active: true, waitingQueues: waiting(2) })
      await pushState({ active: true, waitingQueues: waiting(2) })

      expect(soundsPlayed()).toBe(0)
      expect(NotificationStub.instances).toHaveLength(0)
    })

    it('stays quiet while the agent is unavailable', async () => {
      await renderHost({ active: false })

      await pushState({ active: false, waitingQueues: waiting(1) })

      expect(soundsPlayed()).toBe(0)
      expect(NotificationStub.instances).toHaveLength(0)
    })

    it('stays quiet about the customers who waited while the agent was unavailable', async () => {
      await renderHost({ active: false })

      await pushState({ active: false, waitingQueues: waiting(2) })
      await pushState({ active: true, waitingQueues: waiting(2) })

      expect(soundsPlayed()).toBe(0)

      await pushState({ active: true, waitingQueues: waiting(3) })

      expect(soundsPlayed()).toBe(1)
    })

    it.each(['default', 'denied'] as const)(
      'plays the sound but shows no notification without the browser permission (%s)',
      async (permission) => {
        NotificationStub.permission = permission

        await renderHost()

        await pushState({ active: true, waitingQueues: waiting(1) })

        expect(soundsPlayed()).toBe(1)
        expect(NotificationStub.instances).toHaveLength(0)
      },
    )

    it('opens the chat page from the notification', async () => {
      await renderHost()

      await pushState({ active: true, waitingQueues: waiting(1) })

      const focus = vi.spyOn(window, 'focus').mockImplementation(() => undefined)

      NotificationStub.instances[0].onclick?.()
      await waitUntil(() => getTestRouter().currentRoute.value.name === 'Chat')

      expect(focus).toHaveBeenCalled()
      expect(NotificationStub.instances[0].close).toHaveBeenCalled()
    })

    it('closes the notification when the window gets the focus', async () => {
      await renderHost()

      await pushState({ active: true, waitingQueues: waiting(1) })

      window.dispatchEvent(new Event('focus'))

      expect(NotificationStub.instances[0].close).toHaveBeenCalledOnce()
    })

    it('lets a notification in front of the agent go away by itself', async () => {
      vi.useFakeTimers({ shouldAdvanceTime: true })
      setWindowFocus(true)

      await renderHost()

      await pushState({ active: true, waitingQueues: waiting(1) })

      await waitUntil(() => NotificationStub.instances.length === 1)

      expect(NotificationStub.instances[0].close).not.toHaveBeenCalled()

      await vi.advanceTimersByTimeAsync(4000)

      expect(NotificationStub.instances[0].close).toHaveBeenCalledOnce()
    })

    it('leaves the announcing to the tab the agent used last', async () => {
      mockWebLocks()

      const otherTab = holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK)

      await renderHost()

      await pushState({ active: true, waitingQueues: waiting(1) })

      expect(soundsPlayed()).toBe(0)
      expect(NotificationStub.instances).toHaveLength(0)

      // The other tab is closed, so the next customer is this tab's to announce.
      otherTab.release()
      await waitForNextTick(true)

      await pushState({ active: true, waitingQueues: waiting(2) })

      expect(soundsPlayed()).toBe(1)
      expect(NotificationStub.instances).toHaveLength(1)
    })

    it('does not query without the chat permission', async () => {
      mockChatAgent({ permissions: ['ticket.agent'] })

      renderComponent(Host, { router: true, routerRoutes, store: true })

      await waitForNextTick()

      expect(getGraphQLMockCalls(ChatAgentStateDocument)).toHaveLength(0)
      expect(getGraphQLMockCalls(ChatPreferencesDocument)).toHaveLength(0)
      expect(soundsPlayed()).toBe(0)
      expect(NotificationStub.instances).toHaveLength(0)
    })
  })

  describe('the chat nobody answers', () => {
    beforeEach(() => {
      vi.useFakeTimers({ shouldAdvanceTime: true })

      mockChatAgentAvailabilityUpdateMutation({
        chatAgentAvailabilityUpdate: { active: false, errors: null },
      })
    })

    const advance = (seconds: number) => vi.advanceTimersByTimeAsync(seconds * 1000)

    it('switches the agent unavailable after the configured time and tells them', async () => {
      await renderHost({ waitingQueues: waiting(1) })

      await advance(IDLE_TIMEOUT_SECONDS - 1)

      expect(availabilityWrites()).toHaveLength(0)

      await advance(2)

      await waitUntil(() => availabilityWrites().length === 1)

      expect(availabilityWrites()[0].variables).toEqual({ active: false })
      expect(useNotifications().notifications.value).toEqual([
        expect.objectContaining({
          message: 'Chat not answered, automatically set to offline.',
        }),
      ])
    })

    it('keeps the notice until the agent closes it', async () => {
      await renderHost({ waitingQueues: waiting(1) })

      await advance(IDLE_TIMEOUT_SECONDS + 1)

      await waitUntil(() => availabilityWrites().length === 1)

      await advance(10)

      expect(availabilityWrites()).toHaveLength(1)
      expect(useNotifications().notifications.value).toEqual([
        expect.objectContaining({
          message: 'Chat not answered, automatically set to offline.',
        }),
      ])
    })

    it.each(['', 'soon', '0', '-5'])(
      'waits the default time for the unusable value "%s"',
      async (value) => {
        mockApplicationConfig({ chat: true, chat_agent_idle_timeout: value })

        await renderHost({ waitingQueues: waiting(1) })

        await advance(DEFAULT_IDLE_TIMEOUT_SECONDS - 1)

        expect(availabilityWrites()).toHaveLength(0)

        await advance(2)

        await waitUntil(() => availabilityWrites().length === 1)
      },
    )

    it('reads the number at the start of the value, like the old interface', async () => {
      mockApplicationConfig({ chat: true, chat_agent_idle_timeout: '45s' })

      await renderHost({ waitingQueues: waiting(1) })

      await advance(44)

      expect(availabilityWrites()).toHaveLength(0)

      await advance(2)

      await waitUntil(() => availabilityWrites().length === 1)
    })

    it('does not start while nobody is waiting', async () => {
      await renderHost()

      await advance(IDLE_TIMEOUT_SECONDS + 5)

      expect(availabilityWrites()).toHaveLength(0)
    })

    it('does not start while the agent is unavailable', async () => {
      await renderHost({ active: false, waitingQueues: waiting(1) })

      await advance(IDLE_TIMEOUT_SECONDS + 5)

      expect(availabilityWrites()).toHaveLength(0)
    })

    it('stops when the last customer is gone', async () => {
      await renderHost({ waitingQueues: waiting(1) })

      await advance(IDLE_TIMEOUT_SECONDS - 5)
      await pushState({ active: true, waitingQueues: waiting(0) })
      await advance(IDLE_TIMEOUT_SECONDS)

      expect(availabilityWrites()).toHaveLength(0)
    })

    it('stops when the agent switches off', async () => {
      await renderHost({ waitingQueues: waiting(1) })

      await advance(IDLE_TIMEOUT_SECONDS - 5)
      await pushState({ active: false, waitingQueues: waiting(1) })
      await advance(IDLE_TIMEOUT_SECONDS)

      expect(availabilityWrites()).toHaveLength(0)
    })

    it('starts the wait over when the agent takes one of several customers', async () => {
      await renderHost({ waitingQueues: waiting(2) })

      await advance(IDLE_TIMEOUT_SECONDS - 5)

      // One taken, one still waiting.
      await pushState({
        active: true,
        waitingQueues: waiting(1),
        runningSessions: [runningSession(9, currentAgent)],
      })

      await advance(IDLE_TIMEOUT_SECONDS - 5)

      expect(availabilityWrites()).toHaveLength(0)

      await advance(10)

      await waitUntil(() => availabilityWrites().length === 1)
    })

    it('does not start while the agent is at their chat limit', async () => {
      mockChatPreferences({ maxWindows: 1 })

      await renderHost({
        waitingQueues: waiting(1),
        runningSessions: [runningSession(9, currentAgent)],
      })

      await advance(IDLE_TIMEOUT_SECONDS + 5)

      expect(availabilityWrites()).toHaveLength(0)
    })

    it('stops when the agent takes a customer and reaches their chat limit', async () => {
      mockChatPreferences({ maxWindows: 1 })

      await renderHost({ waitingQueues: waiting(2) })

      await advance(IDLE_TIMEOUT_SECONDS - 5)

      await pushState({
        active: true,
        waitingQueues: waiting(1),
        runningSessions: [runningSession(9, currentAgent)],
      })

      await advance(IDLE_TIMEOUT_SECONDS)

      expect(availabilityWrites()).toHaveLength(0)
    })

    it('starts when a closed chat brings the agent below their chat limit', async () => {
      mockChatPreferences({ maxWindows: 1 })

      await renderHost({
        waitingQueues: waiting(1),
        runningSessions: [runningSession(9, currentAgent)],
      })

      await pushState({ active: true, waitingQueues: waiting(1), runningSessions: [] })
      await advance(IDLE_TIMEOUT_SECONDS + 1)

      await waitUntil(() => availabilityWrites().length === 1)
    })

    it('starts for a customer who arrives later', async () => {
      await renderHost()

      await pushState({ active: true, waitingQueues: waiting(1) })
      await advance(IDLE_TIMEOUT_SECONDS + 1)

      await waitUntil(() => availabilityWrites().length === 1)
    })

    it('tries again after another idle period when the write fails, without saying it switched off', async () => {
      mockChatAgentAvailabilityUpdateMutation(() => Promise.reject(new Error('Network down')))

      await renderHost({ waitingQueues: waiting(1) })

      await advance(IDLE_TIMEOUT_SECONDS + 1)

      await waitUntil(() => availabilityWrites().length === 1)
      await waitForNextTick(true)

      expect(useNotifications().notifications.value).toEqual([
        expect.objectContaining({ message: 'The chat availability could not be updated.' }),
      ])

      await advance(IDLE_TIMEOUT_SECONDS + 1)

      await waitUntil(() => availabilityWrites().length === 2)
    })

    it('switches off without a notice in a tab the agent did not use last', async () => {
      mockWebLocks()

      holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK)

      await renderHost({ waitingQueues: waiting(1) })

      await advance(IDLE_TIMEOUT_SECONDS + 1)

      await waitUntil(() => availabilityWrites().length === 1)

      expect(useNotifications().notifications.value).toEqual([])
    })
  })

  describe('with the session', () => {
    it('closes its notification and stops the idle time once the session is over', async () => {
      vi.useFakeTimers({ shouldAdvanceTime: true })

      await renderHost({ waitingQueues: waiting(1) })

      await pushState({ active: true, waitingQueues: waiting(2) })

      expect(NotificationStub.instances).toHaveLength(1)

      endSession()

      expect(NotificationStub.instances[0].close).toHaveBeenCalledOnce()

      await vi.advanceTimersByTimeAsync((IDLE_TIMEOUT_SECONDS + 1) * 1000)

      expect(availabilityWrites()).toHaveLength(0)
    })

    // The app root creates the store again for the next session.
    it('announces a waiting customer again in the next session', async () => {
      await renderHost()

      endSession()

      useChatAnnouncementsStore()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentStateDocument).length === 2)
      await waitForNextTick()

      await pushState({ active: true, waitingQueues: waiting(1) })

      expect(soundsPlayed()).toBe(1)
      expect(NotificationStub.instances).toHaveLength(1)
    })
  })
})
