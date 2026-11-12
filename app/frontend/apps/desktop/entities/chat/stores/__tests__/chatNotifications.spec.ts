// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { defineComponent, h, nextTick, ref } from 'vue'

import {
  getGraphQLMockCalls,
  getGraphQLSubscriptionHandler,
} from '#tests/graphql/builders/mocks.ts'
import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { resetGlobalStates } from '#tests/support/mock-globalState.ts'
import {
  holdLockFromAnotherTab,
  mockWebLocks,
  unmockWebLocks,
} from '#tests/support/mock-webLocks.ts'
import { nullableMock, waitForNextTick, waitUntil } from '#tests/support/utils.ts'

import type {
  ChatAgentStateUpdatesSubscription,
  ChatSessionUpdatesSubscription,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { BROWSER_NOTIFICATION_LOCK } from '#desktop/composables/useBrowserNotification.ts'
import ChatWindow from '#desktop/pages/chat/components/ChatWindow.vue'

import {
  agentState,
  chatMessage,
  currentAgent,
  disposeSessionStores,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  mockChatSession,
  runningSession,
} from '../../__tests__/mocks/chat-mocks.ts'
import { useChatWindowPresence } from '../../composables/useChatWindowPresence.ts'
import { ChatAgentStateDocument } from '../../graphql/queries/chatAgentState.api.ts'
import { waitForChatAgentStateQueryCalls } from '../../graphql/queries/chatAgentState.mocks.ts'
import { mockChatSessionQuery } from '../../graphql/queries/chatSession.mocks.ts'
import { getChatAgentStateUpdatesSubscriptionHandler } from '../../graphql/subscriptions/chatAgentStateUpdates.mocks.ts'
import { ChatSessionUpdatesDocument } from '../../graphql/subscriptions/chatSessionUpdates.api.ts'
import { useChatAgentStore } from '../chatAgent.ts'
import { useChatNotificationsStore } from '../chatNotifications.ts'
import { useChatUnreadMessagesStore } from '../chatUnreadMessages.ts'

import type { RouteRecordRaw } from 'vue-router'

// The shared browser notification instance snapshots the permission and the lock when it is
//   created, so every example gets a fresh one.
vi.mock('@vueuse/core', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@vueuse/core')>()),
  createGlobalState: (await import('#tests/support/mock-globalState.ts')).createGlobalState,
}))

// Records what the notifier creates; the global stub of the test setup drops the arguments.
class NotificationStub {
  static permission: NotificationPermission = 'granted'

  static requestPermission = () => Promise.resolve('granted' as NotificationPermission)

  static instances: NotificationStub[] = []

  close = vi.fn()

  onclick: (() => Promise<void> | void) | null = null

  constructor(
    public title: string,
    public options?: NotificationOptions,
  ) {
    // VueUse probes the support with an empty notification.
    if (title) NotificationStub.instances.push(this)
  }
}

// Counts the plays of the message sound.
class AudioStub {
  static instances: AudioStub[] = []

  currentTime = 0

  play = vi.fn(() => Promise.resolve())

  constructor(public src: string) {
    AudioStub.instances.push(this)
  }
}

const soundsPlayed = () =>
  AudioStub.instances.reduce((sum, audio) => sum + audio.play.mock.calls.length, 0)

const setWindowFocus = (focused: boolean) => {
  vi.spyOn(document, 'hasFocus').mockReturnValue(focused)
}

const routerRoutes: RouteRecordRaw[] = [
  { path: '/', name: 'Dashboard', component: { template: 'dashboard' } },
  { path: '/chat', name: 'Chat', component: { template: 'chat' } },
  { path: '/:pathMatch(.*)*', name: 'Error', component: { template: 'error' } },
]

const session = runningSession(1, currentAgent)

const otherSession = runningSession(2, currentAgent)

const missedMessage = chatMessage(8, '<div>Still there?</div>', '2026-11-03T11:10:30Z')

const customerSays = async (
  content = '<div>Anybody there?</div>',
  { sessionId = session.id, author = null as typeof currentAgent | null, messageId = 5 } = {},
) => {
  await getGraphQLSubscriptionHandler<ChatSessionUpdatesSubscription>(ChatSessionUpdatesDocument, {
    sessionId,
  }).trigger(
    nullableMock<ChatSessionUpdatesSubscription>({
      chatSessionUpdates: {
        __typename: 'ChatSessionUpdatesPayload',
        message: chatMessage(messageId, content, '2026-11-03T11:10:00Z', author),
        typing: null,
        notice: null,
        leftBy: null,
        closedBy: null,
      },
    }),
  )
  await waitForNextTick()
}

const pushRunningSessions = async (runningSessions: ReturnType<typeof runningSession>[]) => {
  await getChatAgentStateUpdatesSubscriptionHandler().trigger(
    nullableMock<ChatAgentStateUpdatesSubscription>({
      chatAgentStateUpdates: {
        __typename: 'ChatAgentStateUpdatesPayload',
        agentState: agentState({ runningSessions }),
      },
    }),
  )
  await waitForNextTick()
}

// The unread messages as refs, the way the navigation entry reads them.
const useUnreadMessages = () => storeToRefs(useChatUnreadMessagesStore())

const endSession = () =>
  disposeSessionStores(
    useChatNotificationsStore(),
    useChatUnreadMessagesStore(),
    useChatAgentStore(),
  )

// The host stands for the app root, which outlives the Chat page and reads the count for the navigation.
const renderHost = async ({
  runningSessions = [session],
  withWindow = false,
}: { runningSessions?: ReturnType<typeof runningSession>[]; withWindow?: boolean } = {}) => {
  mockAgentState({ runningSessions })

  let unread!: ReturnType<typeof useUnreadMessages>

  const isWindowOpen = ref(withWindow)

  const focusWindow = vi.fn()

  let presence!: ReturnType<typeof useChatWindowPresence>

  // eslint-disable-next-line vue/one-component-per-file
  const ChatWindowStandIn = defineComponent({
    setup() {
      const windowElement = ref<HTMLElement>()

      const inputElement = ref<HTMLElement>()

      presence = useChatWindowPresence(session.id, {
        windowElement,
        inputElement,
        isOver: false,
        focusWindow,
      })

      // Focusable like the window, so a click on its text moves the focus into it.
      return () =>
        h('section', { ref: windowElement, tabindex: -1 }, [
          h('p', 'Anybody there?'),
          h('textarea', { ref: inputElement, 'aria-label': 'Message' }),
        ])
    },
  })

  // eslint-disable-next-line vue/one-component-per-file
  const Host = defineComponent({
    setup() {
      useChatNotificationsStore()

      unread = useUnreadMessages()

      return () => (isWindowOpen.value ? h(ChatWindowStandIn) : null)
    },
  })

  const view = renderComponent(Host, { router: true, routerRoutes, store: true })

  await waitForChatAgentStateQueryCalls()
  await waitForNextTick()

  const closeWindow = () => {
    isWindowOpen.value = false

    return nextTick()
  }

  // What the window's query brought after a reconnect that the subscription did not.
  const reportMissed = async (message: ReturnType<typeof chatMessage>) => {
    presence.reportMissedMessage(message)
    await nextTick()
  }

  return { view, unread, focusWindow, closeWindow, reportMissed }
}

describe('useChatNotificationsStore', () => {
  beforeEach(() => {
    resetGlobalStates()
    vi.stubGlobal('Notification', NotificationStub)
    vi.stubGlobal('Audio', AudioStub)
    NotificationStub.permission = 'granted'
    NotificationStub.instances = []
    AudioStub.instances = []

    setWindowFocus(false)
    mockChatAgent()
    mockChatEnabled()
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.useRealTimers()
    unmockWebLocks()
  })

  describe('before the agent opened the Chat page', () => {
    it('counts the message, plays the sound and shows it', async () => {
      const { unread } = await renderHost()

      await customerSays('<div>Anybody there?</div>')

      expect(unread.total.value).toBe(1)
      expect(soundsPlayed()).toBe(1)
      expect(AudioStub.instances[0].src).toBe('/assets/sounds/chat_message.mp3')
      expect(NotificationStub.instances).toHaveLength(1)
      expect(NotificationStub.instances[0].title).toBe('Support #1')
      expect(NotificationStub.instances[0].options).toMatchObject({
        body: 'Anybody there?',
        tag: session.id,
        silent: true,
      })

      await customerSays('<div>One</div><div>Two</div>', { messageId: 6 })

      expect(unread.total.value).toBe(2)
      expect(soundsPlayed()).toBe(2)
      expect(NotificationStub.instances[1].options?.body).toBe('One\nTwo')
    })

    it('keeps which messages are unread, per conversation', async () => {
      const { unread } = await renderHost({ runningSessions: [session, otherSession] })

      await customerSays('<div>Hello</div>', { messageId: 5 })
      await customerSays('<div>Anybody there?</div>', { messageId: 6 })
      await customerSays('<div>Hi</div>', { sessionId: otherSession.id, messageId: 7 })

      const unreadIds = (sessionId: string) => [
        ...(unread.unreadMessageIds.value.get(sessionId) ?? []),
      ]

      expect(unreadIds(session.id)).toEqual([
        convertToGraphQLId('Chat::Message', 5),
        convertToGraphQLId('Chat::Message', 6),
      ])
      expect(unreadIds(otherSession.id)).toEqual([convertToGraphQLId('Chat::Message', 7)])
      expect(unread.total.value).toBe(3)
    })

    it('tells about a message once, however often it arrives', async () => {
      const { unread } = await renderHost()

      await customerSays()
      await customerSays()

      expect(unread.total.value).toBe(1)
      expect(soundsPlayed()).toBe(1)
      expect(NotificationStub.instances).toHaveLength(1)
    })

    it('stays quiet about what the agent wrote', async () => {
      const { unread } = await renderHost()

      await customerSays('<div>How can I help?</div>', { author: currentAgent })

      expect(unread.total.value).toBe(0)
      expect(soundsPlayed()).toBe(0)
      expect(NotificationStub.instances).toHaveLength(0)
    })

    it('listens to a conversation the agent accepts later', async () => {
      const { unread } = await renderHost({ runningSessions: [] })

      await pushRunningSessions([otherSession])

      await customerSays('<div>Hello</div>', { sessionId: otherSession.id })

      expect(unread.total.value).toBe(1)
      expect(NotificationStub.instances[0].title).toBe('Support #2')
    })

    it('drops the count and the notification of a conversation that ends', async () => {
      const { unread } = await renderHost()

      await customerSays()

      await pushRunningSessions([])

      expect(unread.total.value).toBe(0)
      expect(NotificationStub.instances[0].close).toHaveBeenCalledOnce()
    })

    it('brings the agent to the Chat page from the notification', async () => {
      const focusSpy = vi.spyOn(window, 'focus').mockImplementation(() => {})

      await renderHost()

      await customerSays()

      await NotificationStub.instances[0].onclick?.()

      expect(focusSpy).toHaveBeenCalledOnce()
      expect(getTestRouter().currentRoute.value.name).toBe('Chat')
      expect(NotificationStub.instances[0].close).toHaveBeenCalled()
    })
  })

  describe('with the window of the conversation', () => {
    it('stays quiet while the agent is in the window', async () => {
      setWindowFocus(true)

      const { view, unread } = await renderHost({ withWindow: true })

      await view.events.click(view.getByLabelText('Message'))

      await customerSays()

      expect(unread.total.value).toBe(0)
      expect(soundsPlayed()).toBe(0)
      expect(NotificationStub.instances).toHaveLength(0)
    })

    it('tells the agent with the cursor in the window of a browser window in the background', async () => {
      const { view, unread } = await renderHost({ withWindow: true })

      await view.events.click(view.getByLabelText('Message'))

      await customerSays()

      expect(unread.total.value).toBe(1)
      expect(soundsPlayed()).toBe(1)
    })

    it('reads the conversation and takes the notification back once the agent comes to the window', async () => {
      const { view, unread } = await renderHost({ withWindow: true })

      await customerSays()

      await view.events.click(view.getByLabelText('Message'))

      expect(unread.total.value).toBe(0)
      expect(NotificationStub.instances[0].close).toHaveBeenCalledOnce()
    })

    describe('when the agent left the tab from the message input', () => {
      // The input stays the active element of the tab, so the browser gives it the focus back.
      const comeBackToMessage = async () => {
        const { view, unread } = await renderHost({ withWindow: true })

        const input = view.getByLabelText('Message')

        await view.events.click(input)

        window.dispatchEvent(new Event('blur'))

        await customerSays()

        window.dispatchEvent(new Event('focus'))
        input.dispatchEvent(new FocusEvent('focusin', { bubbles: true }))

        return { view, unread, input }
      }

      it('keeps it unread once the browser gives the focus back', async () => {
        const { unread } = await comeBackToMessage()

        expect(unread.total.value).toBe(1)
      })

      it('reads it on a click into the message input', async () => {
        const { view, unread, input } = await comeBackToMessage()

        await view.events.click(input)

        expect(unread.total.value).toBe(0)
      })

      it('reads it once the agent writes', async () => {
        const { view, unread } = await comeBackToMessage()

        await view.events.keyboard('Hello')

        expect(unread.total.value).toBe(0)
      })

      it('reads it once the agent comes to the message input again', async () => {
        const { view, unread, input } = await comeBackToMessage()

        await view.events.click(view.getByText('Anybody there?'))

        input.focus()

        expect(unread.total.value).toBe(0)
      })

      it('reads it on a click on the notification', async () => {
        vi.spyOn(window, 'focus').mockImplementation(() => {})

        const { unread } = await comeBackToMessage()

        await NotificationStub.instances[0].onclick?.()

        expect(unread.total.value).toBe(0)
      })
    })

    it('keeps it unread on a click elsewhere in the window', async () => {
      const { view, unread } = await renderHost({ withWindow: true })

      await customerSays()

      await view.events.click(view.getByText('Anybody there?'))

      expect(unread.total.value).toBe(1)
    })

    it('tells the agent who reads back in the window rather than writing', async () => {
      setWindowFocus(true)

      const { view, unread } = await renderHost({ withWindow: true })

      await view.events.click(view.getByText('Anybody there?'))

      await customerSays()

      expect(unread.total.value).toBe(1)
      expect(soundsPlayed()).toBe(1)
    })

    it('keeps the count of a conversation that ends until its window is closed', async () => {
      const { unread, closeWindow } = await renderHost({ withWindow: true })

      await customerSays()

      await pushRunningSessions([])

      expect(unread.total.value).toBe(1)
      expect(NotificationStub.instances[0].close).not.toHaveBeenCalled()

      await closeWindow()

      expect(unread.total.value).toBe(0)
      expect(NotificationStub.instances[0].close).toHaveBeenCalledOnce()
    })

    it('counts what the window brought after a reconnect', async () => {
      const { unread, reportMissed } = await renderHost({ withWindow: true })

      await reportMissed(missedMessage)

      expect(unread.total.value).toBe(1)
      expect(soundsPlayed()).toBe(1)
    })

    // The subscription can bring what the window's query already brought.
    it('counts no message again that arrives a second time after the agent read it', async () => {
      const { view, unread, reportMissed } = await renderHost({ withWindow: true })

      await reportMissed(missedMessage)

      await view.events.click(view.getByLabelText('Message'))

      await customerSays('<div>Still there?</div>', { messageId: 8 })

      expect(unread.total.value).toBe(0)
      expect(soundsPlayed()).toBe(1)
      expect(NotificationStub.instances).toHaveLength(1)
    })

    // A window opened from search, or of a session that went elsewhere, is not the agent's to read.
    it('counts nothing the window brought for a conversation the agent does not run', async () => {
      const { unread, reportMissed } = await renderHost({ runningSessions: [], withWindow: true })

      await reportMissed(missedMessage)

      expect(unread.total.value).toBe(0)
      expect(soundsPlayed()).toBe(0)
      expect(NotificationStub.instances).toHaveLength(0)
    })

    it('moves the focus into the window from the notification', async () => {
      vi.spyOn(window, 'focus').mockImplementation(() => {})

      const { focusWindow } = await renderHost({ withWindow: true })

      await customerSays()

      await NotificationStub.instances[0].onclick?.()

      expect(focusWindow).toHaveBeenCalledOnce()
    })

    // The real window: on the first open of the Chat page its composer is not there until the
    //   conversation loaded, which the click on the notification does not wait for.
    it('moves the focus into the composer once the conversation loaded after the click', async () => {
      vi.spyOn(window, 'focus').mockImplementation(() => {})
      mockAgentState({ runningSessions: [session] })
      mockChatSessionQuery(() => Promise.reject(new Error('Network down')))

      // eslint-disable-next-line vue/one-component-per-file
      const Host = defineComponent({
        setup() {
          useChatNotificationsStore()

          return () => h(ChatWindow, { sessionId: session.id })
        },
      })

      const view = renderComponent(Host, { router: true, routerRoutes, store: true, form: true })

      await view.findByText('The conversation could not be loaded.')

      await customerSays()

      await NotificationStub.instances[0].onclick?.()

      mockChatSession(session, [])

      await view.events.click(view.getByRole('button', { name: 'Try again' }))

      expect(await view.findByLabelText('Message')).toHaveFocus()
    })

    it('reads the conversation the notification brought the agent into once it loaded', async () => {
      vi.spyOn(window, 'focus').mockImplementation(() => {})
      mockAgentState({ runningSessions: [session] })

      let loadConversation!: () => void

      mockChatSessionQuery(
        () =>
          new Promise((resolve) => {
            loadConversation = () => resolve({ chatSession: { ...session, messages: [] } })
          }),
      )

      let unread!: ReturnType<typeof useUnreadMessages>

      // eslint-disable-next-line vue/one-component-per-file
      const Host = defineComponent({
        setup() {
          useChatNotificationsStore()

          unread = useUnreadMessages()

          return () => h(ChatWindow, { sessionId: session.id })
        },
      })

      const view = renderComponent(Host, { router: true, routerRoutes, store: true, form: true })

      await view.findByRole('region', { name: 'Support #1' })

      await customerSays()

      expect(unread.total.value).toBe(1)

      await NotificationStub.instances[0].onclick?.()

      loadConversation()

      expect(await view.findByLabelText('Message')).toHaveFocus()
      expect(unread.total.value).toBe(0)
    })
  })

  describe('with more than one tab', () => {
    it('counts in every tab, but leaves the sound and the notification to the tab the agent used last', async () => {
      mockWebLocks()
      holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK)

      const { unread } = await renderHost()

      await customerSays()

      expect(unread.total.value).toBe(1)
      expect(soundsPlayed()).toBe(0)
      expect(NotificationStub.instances).toHaveLength(0)
    })

    it('takes the notification back when another tab takes over', async () => {
      mockWebLocks()

      await renderHost()

      await customerSays()

      holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK, true)
      await waitForNextTick(true)

      expect(NotificationStub.instances[0].close).toHaveBeenCalledOnce()
    })
  })

  it('takes the notification back once the browser window is in front', async () => {
    await renderHost()

    await customerSays()

    window.dispatchEvent(new Event('focus'))

    expect(NotificationStub.instances[0].close).toHaveBeenCalledOnce()
  })

  it('plays the sound without the permission for browser notifications', async () => {
    NotificationStub.permission = 'denied'

    await renderHost()

    await customerSays()

    expect(soundsPlayed()).toBe(1)
    expect(NotificationStub.instances).toHaveLength(0)
  })

  it('takes a notification shown in front of the agent back after four seconds', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    setWindowFocus(true)

    await renderHost()

    await customerSays()

    expect(NotificationStub.instances).toHaveLength(1)

    await vi.advanceTimersByTimeAsync(4100)

    expect(NotificationStub.instances[0].close).toHaveBeenCalled()
  })

  describe('with the session', () => {
    it('stops listening and closes its notification once the session is over', async () => {
      await renderHost()

      await customerSays()

      expect(NotificationStub.instances).toHaveLength(1)

      endSession()

      expect(NotificationStub.instances[0].close).toHaveBeenCalledOnce()
      expect(
        getGraphQLSubscriptionHandler<ChatSessionUpdatesSubscription>(ChatSessionUpdatesDocument, {
          sessionId: session.id,
        }).closed(),
      ).toBe(true)
    })

    // The app root creates the store again for the next session.
    it('counts from zero and tells the agent again in the next session', async () => {
      await renderHost()

      await customerSays()

      endSession()

      useChatNotificationsStore()

      await waitUntil(() => getGraphQLMockCalls(ChatAgentStateDocument).length === 2)
      await waitForNextTick()

      await customerSays('<div>Still there?</div>', { messageId: 6 })

      expect(useUnreadMessages().total.value).toBe(1)
      expect(soundsPlayed()).toBe(2)
      expect(NotificationStub.instances).toHaveLength(2)
    })
  })
})
