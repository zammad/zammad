// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import type { ChatAgentStateUpdatesSubscription } from '#shared/graphql/types.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { useSidebarDisplayStore } from '#desktop/components/layout/stores/sidebarDisplay.ts'
import { SidebarName } from '#desktop/components/layout/types.ts'
import type { PageRoute } from '#desktop/components/PageNavigation/navigationItems.ts'
import PageNavigation from '#desktop/components/PageNavigation/PageNavigation.vue'
import {
  agentState,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  salesTopic,
  supportTopic,
  waitingSessions,
} from '#desktop/entities/chat/__tests__/mocks/chat-mocks.ts'
import { ChatAgentAvailabilityUpdateDocument } from '#desktop/entities/chat/graphql/mutations/chatAgentAvailabilityUpdate.api.ts'
import {
  mockChatAgentAvailabilityUpdateMutation,
  mockChatAgentAvailabilityUpdateMutationError,
  waitForChatAgentAvailabilityUpdateMutationCalls,
} from '#desktop/entities/chat/graphql/mutations/chatAgentAvailabilityUpdate.mocks.ts'
import { waitForChatAgentStateQueryCalls } from '#desktop/entities/chat/graphql/queries/chatAgentState.mocks.ts'
import { getChatAgentStateUpdatesSubscriptionHandler } from '#desktop/entities/chat/graphql/subscriptions/chatAgentStateUpdates.mocks.ts'
import { useChatUnreadMessagesStore } from '#desktop/entities/chat/stores/chatUnreadMessages.ts'

import chatRoutes from '../routes.ts'

const [chatRoute] = chatRoutes

const chat: PageRoute = {
  path: chatRoute.path,
  name: chatRoute.name as string,
  meta: chatRoute.meta as PageRoute['meta'],
}

// The real chat route, and only that one, as the navigation's item list.
vi.mock('#desktop/components/PageNavigation/navigationItems.ts', () => ({
  get navigationItems() {
    return [{ type: 'route', order: 350, route: chat }]
  },
  numberOfPermanentItems: 0,
}))

const routerRoutes = [
  { path: '/', name: 'Root', component: { template: 'root' } },
  { path: '/chat', name: 'Chat', component: { template: 'chat' } },
]

const mockWaiting = (count: number, active = true) =>
  mockAgentState({
    active,
    waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(count) }],
  })

const setUnreadMessages = (messageIds: Record<string, string[]>) => {
  const { addUnreadMessage } = useChatUnreadMessagesStore()

  Object.entries(messageIds).forEach(([sessionId, ids]) =>
    ids.forEach((messageId) => addUnreadMessage(sessionId, messageId)),
  )
}

const waitForState = async () => {
  await waitForChatAgentStateQueryCalls()
  await waitForNextTick()
}

const renderNavigation = (collapsed = false) =>
  renderComponent(PageNavigation, {
    router: true,
    routerRoutes,
    store: true,
    form: true,
    props: { collapsed },
  })

describe('chat navigation entry', () => {
  beforeEach(() => {
    mockWaiting(3)
    mockChatAgent()
    mockChatEnabled()
    mockChatAgentAvailabilityUpdateMutation({
      chatAgentAvailabilityUpdate: { active: false, errors: null },
    })
  })

  // The collapsed state is persisted and the notifications are shared, so they would leak into the
  //   next example.
  afterEach(() => {
    localStorage.clear()
    useNotifications().clearAllNotifications()
  })

  it.each([false, true])('has no accessibility violations (collapsed: %s)', async (collapsed) => {
    const view = renderNavigation(collapsed)

    await waitForState()

    await expect(view.container).toBeAccessible()
  })

  it('links to the chat page and shows the waiting customers', async () => {
    const view = renderNavigation()

    const link = await view.findByRole('link', { name: 'Customer Chat 3 waiting customers' })

    expect(link).toHaveAttribute('href', '/desktop/chat')
    expect(link).toHaveTextContent('3')
    expect(view.getByIconName('chat')).toBeInTheDocument()
  })

  it('shows no counter without waiting customers', async () => {
    mockWaiting(0)

    const view = renderNavigation()

    await waitForState()

    expect(view.getByRole('link', { name: 'Customer Chat' })).toHaveTextContent(/^Customer Chat$/)
  })

  it('names a single waiting customer in the singular', async () => {
    mockWaiting(1)

    const view = renderNavigation()

    expect(
      await view.findByRole('link', { name: 'Customer Chat 1 waiting customer' }),
    ).toBeInTheDocument()
  })

  it('caps the counter at 99+', async () => {
    mockWaiting(100)

    const view = renderNavigation()

    expect(
      await view.findByRole('link', { name: 'Customer Chat 100 waiting customers' }),
    ).toHaveTextContent('99+')
  })

  it('adds the unread messages of the chat windows to the waiting customers', async () => {
    mockWaiting(2)
    setUnreadMessages({ 'session-1': ['message-1'] })

    const view = renderNavigation()

    expect(
      await view.findByRole('link', {
        name: 'Customer Chat 2 waiting customers, 1 unread message',
      }),
    ).toHaveTextContent('3')
  })

  it('shows the unread messages of all windows while nobody waits', async () => {
    mockWaiting(0)
    setUnreadMessages({ 'session-1': ['message-1', 'message-2'], 'session-2': ['message-3'] })

    const view = renderNavigation()

    expect(
      await view.findByRole('link', { name: 'Customer Chat 3 unread messages' }),
    ).toHaveTextContent('3')
  })

  it('is absent without the chat.agent permission', () => {
    mockPermissions(['ticket.agent'])

    const view = renderNavigation()

    expect(view.queryByRole('link', { name: /Customer Chat/ })).not.toBeInTheDocument()
  })

  it('is absent while the chat feature is off', () => {
    mockChatEnabled(false)

    const view = renderNavigation()

    expect(view.queryByRole('link', { name: /Customer Chat/ })).not.toBeInTheDocument()
  })

  describe('on the chat page', () => {
    afterEach(async () => {
      await getTestRouter().push('/')
    })

    it('highlights the entry and turns the counter white', async () => {
      const view = renderNavigation()

      const link = await view.findByRole('link', { name: 'Customer Chat 3 waiting customers' })

      await getTestRouter().push('/chat')

      expect(link).toHaveClass('bg-blue-800!')
      expect(view.getByText('3', { selector: '[aria-hidden]' }).parentElement).toHaveClass(
        'bg-white!',
      )
    })
  })

  describe('availability switch', () => {
    it('reflects the stored availability', async () => {
      const view = renderNavigation()

      await waitForState()

      expect(view.getByRole('switch', { name: 'Chat availability' })).toHaveAttribute(
        'aria-checked',
        'true',
      )
    })

    it('does not write the availability it was given by the state', async () => {
      const view = renderNavigation()

      await waitForState()

      expect(view.getByRole('switch', { name: 'Chat availability' })).toHaveAttribute(
        'aria-checked',
        'true',
      )
      expect(getGraphQLMockCalls(ChatAgentAvailabilityUpdateDocument)).toHaveLength(0)
    })

    it('follows a pushed availability without writing it', async () => {
      const view = renderNavigation()

      await waitForState()

      await getChatAgentStateUpdatesSubscriptionHandler().trigger(
        nullableMock<ChatAgentStateUpdatesSubscription>({
          chatAgentStateUpdates: {
            __typename: 'ChatAgentStateUpdatesPayload',
            agentState: agentState({ active: false }),
          },
        }),
      )
      await waitForNextTick()

      expect(view.getByRole('switch', { name: 'Chat availability' })).toHaveAttribute(
        'aria-checked',
        'false',
      )
      expect(getGraphQLMockCalls(ChatAgentAvailabilityUpdateDocument)).toHaveLength(0)
    })

    it('turns back and reports a failed write', async () => {
      mockChatAgentAvailabilityUpdateMutationError('Something went wrong', {
        type: GraphQLErrorTypes.UnknownError,
      })

      const view = renderNavigation()

      await waitForState()

      const switcher = view.getByRole('switch', { name: 'Chat availability' })

      await view.events.click(switcher)

      const calls = await waitForChatAgentAvailabilityUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ active: false })
      await vi.waitFor(() => expect(switcher).toHaveAttribute('aria-checked', 'true'))
      expect(useNotifications().notifications.value).toEqual([
        expect.objectContaining({ message: 'The chat availability could not be updated.' }),
      ])
    })

    it('toggles the availability without navigating', async () => {
      const view = renderNavigation()

      await waitForState()

      // What the state answers once the write is through.
      mockWaiting(3, false)

      await view.events.click(view.getByRole('switch', { name: 'Chat availability' }))

      expect(view.getByRole('switch', { name: 'Chat availability' })).toHaveAttribute(
        'aria-checked',
        'false',
      )

      const calls = await waitForChatAgentAvailabilityUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ active: false })
      expect(getTestRouter().push).not.toHaveBeenCalled()
      expect(getTestRouter().currentRoute.value.path).toBe('/')
    })

    it('toggles with the keyboard without navigating', async () => {
      const view = renderNavigation()

      await waitForState()

      const switcher = view.getByRole('switch', { name: 'Chat availability' })

      mockWaiting(3, false)

      switcher.focus()
      await view.events.keyboard(' ')

      expect(switcher).toHaveAttribute('aria-checked', 'false')

      await waitForChatAgentAvailabilityUpdateMutationCalls()

      expect(getTestRouter().push).not.toHaveBeenCalled()
    })

    describe('without a selected topic', () => {
      const hint =
        'You need to subscribe to at least one topic in the settings to enable chat availability.'

      // Among several topics the agent has to choose; a single one the server takes on its own.
      const mockSeveralTopics = (active: boolean) =>
        mockAgentState({ active, topics: [salesTopic, supportTopic] })

      beforeEach(() => {
        mockChatAgent({ selectedTopics: [] })
      })

      it('switches on when there is only one topic, which the server takes', async () => {
        mockWaiting(0, false)
        mockChatAgentAvailabilityUpdateMutation({
          chatAgentAvailabilityUpdate: { active: true, errors: null },
        })

        const view = renderNavigation()

        await waitForState()

        const switcher = view.getByRole('switch', { name: 'Chat availability' })

        expect(switcher).toHaveAttribute('aria-disabled', 'false')

        await view.events.click(switcher)

        const availabilityCalls = await waitForChatAgentAvailabilityUpdateMutationCalls()

        expect(availabilityCalls.at(-1)?.variables).toEqual({ active: true })
        expect(useNotifications().notifications.value).toEqual([])
      })

      it('is marked disabled among several topics and tells why, on hover and to a screen reader', async () => {
        mockSeveralTopics(false)

        const view = renderNavigation()

        await waitForState()

        const switcher = view.getByRole('switch', { name: 'Chat availability' })

        expect(switcher).toHaveAttribute('aria-disabled', 'true')
        expect(switcher).toHaveAttribute('aria-description', hint)

        await view.events.hover(switcher)

        expect(await view.findByText(hint)).toBeInTheDocument()
      })

      it('ignores a click among several topics and stays off', async () => {
        mockSeveralTopics(false)

        const view = renderNavigation()

        await waitForState()

        const switcher = view.getByRole('switch', { name: 'Chat availability' })

        await view.events.click(switcher)
        await waitForNextTick()

        expect(switcher).toHaveAttribute('aria-checked', 'false')
        expect(useNotifications().notifications.value).toEqual([])
        expect(getGraphQLMockCalls(ChatAgentAvailabilityUpdateDocument)).toHaveLength(0)
      })

      it('stays enabled for an agent still available, so they can switch off', async () => {
        mockSeveralTopics(true)

        const view = renderNavigation()

        await waitForState()

        const switcher = view.getByRole('switch', { name: 'Chat availability' })

        expect(switcher).toHaveAttribute('aria-disabled', 'false')

        await view.events.click(switcher)

        await waitForChatAgentAvailabilityUpdateMutationCalls()
      })
    })
  })

  describe('collapsed sidebar', () => {
    it('shows an icon with a dot for waiting customers and no switch', async () => {
      const view = renderNavigation(true)

      const dot = (await view.findByText('3 waiting customers')).parentElement as HTMLElement
      const button = view.getByLabelText('Customer Chat')

      expect(button).toHaveAttribute('aria-describedby', dot.id)
      expect(dot).toHaveAttribute('data-test-id', 'common-badge')
      expect(view.getByIconName('chat')).toBeInTheDocument()
      expect(view.queryByRole('switch')).not.toBeInTheDocument()
    })

    it('shows the dot for unread messages while nobody waits', async () => {
      mockWaiting(0)
      setUnreadMessages({ 'session-1': ['message-1'] })

      const view = renderNavigation(true)

      const dot = (await view.findByText('1 unread message')).parentElement as HTMLElement

      expect(view.getByLabelText('Customer Chat')).toHaveAttribute('aria-describedby', dot.id)
    })

    it('shows no dot without waiting customers', async () => {
      mockWaiting(0)

      const view = renderNavigation(true)

      await waitForState()

      expect(view.getByLabelText('Customer Chat')).not.toHaveAttribute('aria-describedby')
    })

    it('opens the chat page on click', async () => {
      const sidebar = useSidebarDisplayStore()
      sidebar.setCollapsed(SidebarName.Primary, true)

      const view = renderNavigation(true)

      await waitForState()
      await view.events.click(view.getByLabelText('Customer Chat'))

      expect(getTestRouter().push).toHaveBeenCalledWith('/chat')
    })
  })
})
