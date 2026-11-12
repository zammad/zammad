// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import {
  EnumChatSessionState,
  type ChatAgentStateUpdatesSubscription,
} from '#shared/graphql/types.ts'

import {
  agentState,
  chatSession,
  colleague,
  currentAgent,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  mockChatPreferences,
  mockChatSession,
  mockChatSessions,
  preferencesTopic,
  runningSession,
  salesTopic,
  supportTopic,
  waitingSessions,
} from '#desktop/entities/chat/__tests__/mocks/chat-mocks.ts'
import {
  mockChatSessionAcceptMutation,
  waitForChatSessionAcceptMutationCalls,
} from '#desktop/entities/chat/graphql/mutations/chatSessionAccept.mocks.ts'
import { waitForChatAgentStateQueryCalls } from '#desktop/entities/chat/graphql/queries/chatAgentState.mocks.ts'
import { getChatAgentStateUpdatesSubscriptionHandler } from '#desktop/entities/chat/graphql/subscriptions/chatAgentStateUpdates.mocks.ts'

const waitForState = async () => {
  await waitForChatAgentStateQueryCalls()
  await waitForNextTick()
}

describe('Chat', () => {
  beforeEach(() => {
    mockChatAgent()
    mockChatEnabled()
    mockChatSession()
  })

  it('shows the empty page without waiting customers and a conversation of the agent', async () => {
    mockAgentState({ runningSessions: [runningSession(1, colleague)] })

    const view = await visitView('/chat')

    expect(await view.findByRole('heading', { name: 'No waiting customers' })).toBeInTheDocument()
    expect(view.getByText('All chats have been answered.')).toBeInTheDocument()
    expect(view.getByRole('img', { name: 'confetti' })).toBeInTheDocument()
  })

  it('opens the chat settings from the page', async () => {
    mockAgentState()
    mockChatPreferences({ topics: [preferencesTopic(supportTopic, true)] })

    const view = await visitView('/chat')

    await view.events.click(await view.findByRole('button', { name: 'Settings' }))

    expect(await view.findByRole('heading', { name: 'Chat settings' })).toBeInTheDocument()
    expect(await view.findByLabelText('Max. concurrent chats')).toHaveValue(4)
  })

  it('shows no empty page while the agent has a conversation', async () => {
    mockAgentState({ runningSessions: [runningSession(1, currentAgent)] })

    const view = await visitView('/chat')

    await waitForState()

    expect(view.queryByRole('heading', { name: 'No waiting customers' })).not.toBeInTheDocument()
  })

  it('shows a window per conversation in the order of the state, and keeps the order when one is closed', async () => {
    // The third conversation has ended, which is what lets the agent close its window.
    const sessions = [1, 2, 3, 4, 5].map((id) =>
      id === 3
        ? chatSession(id, { state: EnumChatSessionState.Closed, user: currentAgent })
        : runningSession(id, currentAgent),
    )

    mockAgentState({ runningSessions: sessions })
    mockChatSessions(sessions)

    const view = await visitView('/chat')

    const titles = () =>
      view
        .getAllByRole('region', { name: /^Support #/ })
        .map((window) => window.getAttribute('aria-label'))

    await view.findByRole('button', { name: 'Close window' })

    expect(titles()).toEqual(['Support #1', 'Support #2', 'Support #3', 'Support #4', 'Support #5'])

    await view.events.click(view.getByRole('button', { name: 'Close window' }))

    expect(titles()).toEqual(['Support #1', 'Support #2', 'Support #4', 'Support #5'])
  })

  it('brings the window of a conversation the agent accepted into view', async () => {
    const running = runningSession(1, currentAgent)
    const accepted = runningSession(2, currentAgent)

    mockAgentState({
      runningSessions: [running],
      waitingQueues: [{ topic: supportTopic, sessions: [chatSession(2)] }],
    })
    mockChatSessions([running, accepted])
    mockChatSessionAcceptMutation({ chatSessionAccept: { session: accepted, errors: null } })

    const view = await visitView('/chat')

    await view.findByRole('region', { name: 'Support #1' })

    const scrollIntoView = vi.mocked(Element.prototype.scrollIntoView)

    scrollIntoView.mockClear()

    await view.events.click(view.getByRole('button', { name: /^Waiting customers/ }))

    await getChatAgentStateUpdatesSubscriptionHandler().trigger(
      nullableMock<ChatAgentStateUpdatesSubscription>({
        chatAgentStateUpdates: {
          __typename: 'ChatAgentStateUpdatesPayload',
          agentState: agentState({ runningSessions: [running, accepted] }),
        },
      }),
    )

    const window = await view.findByRole('region', { name: 'Support #2' })

    await waitFor(() => expect(scrollIntoView.mock.contexts).toEqual([window]))
  })

  it('brings the window of a conversation opened through its link into view', async () => {
    const running = runningSession(1, currentAgent)
    const found = chatSession(2, { state: EnumChatSessionState.Closed, user: colleague })

    mockAgentState({ runningSessions: [running] })
    mockChatSessions([running, found])

    const scrollIntoView = vi.mocked(Element.prototype.scrollIntoView)

    scrollIntoView.mockClear()

    const view = await visitView('/chat/session/2')

    const window = await view.findByRole('region', { name: 'Support #2' })

    await waitFor(() => expect(scrollIntoView.mock.contexts).toContain(window))
  })

  it('shows that customers are waiting while the agent has no conversation, instead of the empty page', async () => {
    mockAgentState({ waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(2) }] })

    const view = await visitView('/chat')

    expect(
      await view.findByRole('heading', { name: /There are waiting customers/ }),
    ).toBeInTheDocument()
    expect(view.getByText('There are waiting customers in the chat queue.')).toBeInTheDocument()
    expect(view.getByText('Are you ready to pick one of them up?')).toBeInTheDocument()
    expect(view.queryByRole('heading', { name: 'No waiting customers' })).not.toBeInTheDocument()
    expect(view.queryByRole('img', { name: 'confetti' })).not.toBeInTheDocument()
  })

  it('accepts the longest waiting customer from there and opens the conversation in place of it', async () => {
    const accepted = runningSession(2, currentAgent)

    mockAgentState({ waitingQueues: [{ topic: supportTopic, sessions: [chatSession(2)] }] })
    mockChatSessions([accepted])

    mockChatSessionAcceptMutation({ chatSessionAccept: { session: accepted, errors: null } })

    const view = await visitView('/chat')

    await view.events.click(await view.findByRole('button', { name: 'Accept chat' }))

    const calls = await waitForChatSessionAcceptMutationCalls()

    // No topic: the longest waiting customer of all topics the agent handles.
    expect(calls.at(-1)?.variables).toEqual({})

    await getChatAgentStateUpdatesSubscriptionHandler().trigger(
      nullableMock<ChatAgentStateUpdatesSubscription>({
        chatAgentStateUpdates: {
          __typename: 'ChatAgentStateUpdatesPayload',
          agentState: agentState({ runningSessions: [accepted] }),
        },
      }),
    )

    expect(await view.findByRole('region', { name: 'Support #2' })).toBeInTheDocument()
    expect(
      view.queryByRole('heading', { name: /There are waiting customers/ }),
    ).not.toBeInTheDocument()
  })

  it('shows no empty page while the agent has a conversation and customers are waiting', async () => {
    // An id apart from those of the waiting customers.
    const running = runningSession(5, currentAgent)

    mockAgentState({
      waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(2) }],
      runningSessions: [running],
    })
    mockChatSessions([running])

    const view = await visitView('/chat')

    await view.findByRole('region', { name: 'Support #5' })

    expect(
      view.queryByRole('heading', { name: /There are waiting customers/ }),
    ).not.toBeInTheDocument()
    expect(view.queryByRole('heading', { name: 'No waiting customers' })).not.toBeInTheDocument()
  })

  describe('without a subscribed chat topic', () => {
    // Among several topics the agent has to choose; a single one the server takes on its own.
    beforeEach(() => {
      mockChatAgent({ selectedTopics: [] })
      mockAgentState({ topics: [salesTopic, supportTopic] })
    })

    it('points to the settings instead of the empty page, and opens them from there', async () => {
      const view = await visitView('/chat')

      expect(
        await view.findByRole('heading', { name: /No subscribed chat topics/ }),
      ).toBeInTheDocument()
      expect(
        view.getByText("Seems like you haven't turned on any of the chat topics yet?"),
      ).toBeInTheDocument()
      expect(
        view.getByText(
          'You need to subscribe to at least one topic in the settings to enable chat availability.',
        ),
      ).toBeInTheDocument()
      expect(view.queryByRole('heading', { name: 'No waiting customers' })).not.toBeInTheDocument()
      expect(view.queryByRole('img', { name: 'confetti' })).not.toBeInTheDocument()

      const settingsButtons = view.getAllByRole('button', { name: 'Settings' })

      expect(settingsButtons).toHaveLength(1)

      await view.events.click(settingsButtons[0])

      expect(await view.findByRole('heading', { name: 'Chat settings' })).toBeInTheDocument()
    })

    it('points to the settings also while customers are waiting', async () => {
      mockAgentState({
        topics: [salesTopic, supportTopic],
        waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(2) }],
      })

      const view = await visitView('/chat')

      expect(
        await view.findByRole('heading', { name: /No subscribed chat topics/ }),
      ).toBeInTheDocument()
      expect(
        view.queryByRole('heading', { name: /There are waiting customers/ }),
      ).not.toBeInTheDocument()
    })

    it('keeps the window of a conversation still open, without the hint before the state is there', async () => {
      mockAgentState({
        topics: [salesTopic, supportTopic],
        runningSessions: [runningSession(1, currentAgent)],
      })

      const view = await visitView('/chat')

      expect(
        view.queryByRole('heading', { name: /No subscribed chat topics/ }),
      ).not.toBeInTheDocument()

      await waitForState()

      expect(await view.findByRole('button', { name: 'Settings' })).toBeInTheDocument()
      expect(
        view.queryByRole('heading', { name: /No subscribed chat topics/ }),
      ).not.toBeInTheDocument()
    })

    it('shows the empty page with a single topic, which the server takes when switching on', async () => {
      mockAgentState({ topics: [supportTopic] })

      const view = await visitView('/chat')

      expect(await view.findByRole('heading', { name: 'No waiting customers' })).toBeInTheDocument()
      expect(
        view.queryByRole('heading', { name: /No subscribed chat topics/ }),
      ).not.toBeInTheDocument()
    })
  })

  it('explains the chat is disabled, with a link for an admin', async () => {
    mockChatEnabled(false)
    mockChatAgent({ permissions: ['chat.agent', 'admin.channel_chat'] })

    const view = await visitView('/chat')

    expect(
      await view.findByText('Sorry, the chat feature is currently disabled.'),
    ).toBeInTheDocument()
    expect(
      view.getByRole('link', { name: 'Enable it in the chat channel settings.' }),
    ).toHaveAttribute('href', '/#channels/chat')
    expect(view.queryByRole('button', { name: 'Settings' })).not.toBeInTheDocument()
  })

  it('explains the chat is disabled without a link for an agent', async () => {
    mockChatEnabled(false)

    const view = await visitView('/chat')

    expect(
      await view.findByText('Sorry, the chat feature is currently disabled.'),
    ).toBeInTheDocument()
    expect(view.queryByRole('link', { name: /chat channel settings/ })).not.toBeInTheDocument()
  })
})
