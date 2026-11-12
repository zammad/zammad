// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumChatSessionState } from '#shared/graphql/types.ts'

import {
  chatSession,
  colleague,
  currentAgent,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  mockChatPreferences,
  mockChatSession,
  runningSession,
  salesTopic,
  supportTopic,
  waitingSessions,
} from '#desktop/entities/chat/__tests__/mocks/chat-mocks.ts'
import {
  mockChatSessionAcceptMutation,
  waitForChatSessionAcceptMutationCalls,
} from '#desktop/entities/chat/graphql/mutations/chatSessionAccept.mocks.ts'

// The counter is the row of label, badge and info button the label sits in.
const counter = (view: Awaited<ReturnType<typeof visitView>>, label: string) =>
  within(view.getByText(label).parentElement as HTMLElement)

const openPopover = async (view: Awaited<ReturnType<typeof visitView>>, triggerLabel: string) =>
  view.events.hover(await view.findByRole('button', { name: triggerLabel }))

describe('Chat toolbar', () => {
  beforeEach(() => {
    mockChatAgent()
    mockChatEnabled()
    mockChatPreferences()
    mockChatSession()
  })

  it('shows the live counts next to their labels', async () => {
    mockAgentState({
      waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(3) }],
      runningSessions: [runningSession(4, currentAgent), runningSession(5, colleague)],
      availableAgents: [currentAgent, colleague],
    })

    const view = await visitView('/chat')

    expect(await view.findByText('Waiting customers')).toBeInTheDocument()
    expect(counter(view, 'Waiting customers').getByText('3')).toBeInTheDocument()
    expect(counter(view, 'Active chat sessions').getByText('2')).toBeInTheDocument()
    expect(counter(view, 'Active agents').getByText('2')).toBeInTheDocument()
  })

  it('shows a zero for an empty counter, without highlighting it', async () => {
    mockAgentState({ availableAgents: [] })

    const view = await visitView('/chat')

    expect(await view.findByText('Waiting customers')).toBeInTheDocument()
    expect(counter(view, 'Waiting customers').getByText('0')).toBeInTheDocument()
    expect(counter(view, 'Active chat sessions').getByText('0')).toBeInTheDocument()
    expect(counter(view, 'Active agents').getByText('0')).toBeInTheDocument()
    expect(counter(view, 'Waiting customers').getByTestId('common-badge')).not.toHaveClass(
      'common-badge-highlight',
    )
  })

  it('highlights only the count of waiting customers', async () => {
    mockAgentState({
      waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(3) }],
      runningSessions: [runningSession(4, currentAgent)],
      availableAgents: [currentAgent],
    })

    const view = await visitView('/chat')

    expect(await view.findByText('Waiting customers')).toBeInTheDocument()
    expect(counter(view, 'Waiting customers').getByTestId('common-badge')).toHaveClass(
      'common-badge-highlight',
    )
    expect(counter(view, 'Active chat sessions').getByTestId('common-badge')).not.toHaveClass(
      'common-badge-highlight',
    )
    expect(counter(view, 'Active agents').getByTestId('common-badge')).not.toHaveClass(
      'common-badge-highlight',
    )
  })

  it('has no toolbar while the chat feature is off', async () => {
    mockChatEnabled(false)

    const view = await visitView('/chat')

    expect(await view.findByText('Sorry, the chat feature is currently disabled.')).toBeVisible()
    expect(view.queryByText('Waiting customers')).not.toBeInTheDocument()
  })

  describe('waiting customers', () => {
    it('lists them with where they are', async () => {
      mockAgentState({
        waitingQueues: [
          {
            topic: supportTopic,
            sessions: [
              chatSession(14),
              chatSession(15, {
                geoIp: {
                  __typename: 'ChatSessionGeoIp',
                  countryName: 'Austria',
                  countryCode: 'AT',
                  cityName: null,
                },
              }),
            ],
          },
        ],
      })

      const view = await visitView('/chat')
      await openPopover(view, 'Show waiting customers')

      expect(await view.findByText('Support #14')).toBeInTheDocument()
      expect(view.getByText('Berlin, Germany')).toBeInTheDocument()
      expect(view.getByText('Support #15')).toBeInTheDocument()
      expect(view.getByText('Austria')).toBeInTheDocument()
      expect(view.queryByText(/^Waiting in/)).not.toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Accept next' })).not.toBeInTheDocument()
    })

    it('shows the agent who transferred a customer, like the old interface', async () => {
      mockAgentState({
        waitingQueues: [
          {
            topic: supportTopic,
            sessions: [chatSession(14), chatSession(15, { user: colleague })],
          },
        ],
      })

      const view = await visitView('/chat')
      await openPopover(view, 'Show waiting customers')

      expect(await view.findByText('Support #15')).toBeInTheDocument()
      expect(view.getAllByText('Transferred from')).toHaveLength(1)
      expect(view.queryByText('Agent')).not.toBeInTheDocument()
      expect(view.getByText('Other Agent')).toBeInTheDocument()
    })

    it('groups them by topic once the agent handles several, longest waiting first', async () => {
      mockAgentState({
        topics: [salesTopic, supportTopic],
        waitingQueues: [
          {
            topic: salesTopic,
            sessions: [
              chatSession(14, { topic: salesTopic, createdAt: '2026-11-03T11:10:00Z' }),
              chatSession(16, { topic: salesTopic, createdAt: '2026-11-03T11:30:00Z' }),
            ],
          },
          {
            topic: supportTopic,
            sessions: [chatSession(15, { createdAt: '2026-11-03T11:20:00Z' })],
          },
        ],
      })

      const view = await visitView('/chat')
      await openPopover(view, 'Show waiting customers')

      const groups = (await view.findByText('Sales #14')).closest('ul')
        ?.parentElement as HTMLElement

      expect(
        within(groups)
          .getAllByText(/^Waiting in/)
          .map((badge) => badge.textContent),
      ).toEqual(['Waiting in Sales', 'Waiting in Support'])
      expect(within(groups).getByText('Sales')).toHaveClass('font-bold')

      const counts = within(groups).getAllByTestId('common-badge')

      expect(counts.map((badge) => badge.textContent?.trim())).toEqual(['2', '1'])
      counts.forEach((badge) => expect(badge).toHaveClass('common-badge-highlight'))

      expect(within(groups).getAllByRole('button', { name: 'Accept next' })).toHaveLength(2)
      expect(
        within(groups)
          .getAllByRole('list')
          .map((list) =>
            within(list)
              .getAllByRole('listitem')
              .map((row) => row.textContent),
          ),
      ).toEqual([
        [expect.stringContaining('Sales #14'), expect.stringContaining('Sales #16')],
        [expect.stringContaining('Support #15')],
      ])
    })

    it('says so when nobody is waiting', async () => {
      mockAgentState({ runningSessions: [runningSession(1, currentAgent)] })

      const view = await visitView('/chat')
      await openPopover(view, 'Show waiting customers')

      expect(await view.findByText('No waiting customers')).toBeInTheDocument()
    })

    it('opens with the keyboard', async () => {
      mockAgentState({ waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(1) }] })

      const view = await visitView('/chat')

      const trigger = await view.findByRole('button', { name: 'Show waiting customers' })

      trigger.focus()
      await view.events.keyboard('{Space}')

      expect(await view.findByText('Support #1')).toBeInTheDocument()
      expect(trigger).toHaveAttribute('aria-expanded', 'true')
    })
  })

  describe('accepting a waiting customer', () => {
    const accepted = chatSession(1, { state: EnumChatSessionState.Running, user: currentAgent })

    // The popover offers a button per topic only to an agent who handles several.
    const severalTopics = (sessions: ReturnType<typeof waitingSessions>) => ({
      topics: [salesTopic, supportTopic],
      waitingQueues: [
        { topic: salesTopic, sessions: [] },
        { topic: supportTopic, sessions },
      ],
    })

    it('takes the next customer of the topic the button belongs to', async () => {
      mockAgentState({
        topics: [salesTopic, supportTopic],
        waitingQueues: [
          { topic: salesTopic, sessions: [chatSession(1, { topic: salesTopic })] },
          { topic: supportTopic, sessions: [chatSession(2)] },
        ],
      })
      mockChatSessionAcceptMutation({ chatSessionAccept: { session: accepted, errors: null } })

      const view = await visitView('/chat')

      await openPopover(view, 'Show waiting customers')

      const buttons = await view.findAllByRole('button', { name: 'Accept next' })

      expect(buttons).toHaveLength(2)

      await view.events.click(buttons[1])

      const calls = await waitForChatSessionAcceptMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ topicId: supportTopic.id })
    })

    it('takes the next customer from the tab too, as in the old interface', async () => {
      mockAgentState({ waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(1) }] })
      mockChatSessionAcceptMutation({ chatSessionAccept: { session: accepted, errors: null } })

      const view = await visitView('/chat')

      const tab = await view.findByRole('button', { name: /^Waiting customers/ })

      expect(tab).toHaveAccessibleDescription('Accept next')
      expect(view.queryByRole('button', { name: /^Active chat sessions/ })).not.toBeInTheDocument()
      expect(view.queryByRole('button', { name: /^Active agents/ })).not.toBeInTheDocument()

      await view.events.click(tab)

      const calls = await waitForChatSessionAcceptMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({})
    })

    it('keeps the tab ready while a customer is being accepted, and takes only one', async () => {
      mockAgentState({ waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(2) }] })

      let answer = () => {}

      mockChatSessionAcceptMutation(
        () =>
          new Promise((resolve) => {
            answer = () => resolve({ chatSessionAccept: { session: accepted, errors: null } })
          }),
      )

      const view = await visitView('/chat')

      const tab = await view.findByRole('button', { name: /^Waiting customers/ })

      await view.events.click(tab)
      await waitForChatSessionAcceptMutationCalls()

      expect(tab).not.toBeDisabled()

      await view.events.click(tab)

      expect(await waitForChatSessionAcceptMutationCalls()).toHaveLength(1)

      answer()
    })

    it('leaves the tab disabled while nobody waits', async () => {
      mockAgentState()

      const view = await visitView('/chat')

      expect(await view.findByRole('button', { name: /^Waiting customers/ })).toBeDisabled()
    })

    it('leaves the tab disabled, with the reason, at the limit of concurrent chats of the agent', async () => {
      mockChatPreferences({ maxWindows: 1 })
      mockAgentState({
        waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(1) }],
        runningSessions: [runningSession(4, currentAgent)],
      })

      const view = await visitView('/chat')

      const tab = await view.findByRole('button', { name: /^Waiting customers/ })

      await waitFor(() => expect(tab).toBeDisabled())

      expect(tab).toHaveAccessibleDescription(
        'You have reached the maximum number of concurrent chats.',
      )
    })

    it('is disabled at the limit of concurrent chats of the agent, with the reason once for all topics', async () => {
      mockChatPreferences({ maxWindows: 2 })
      mockAgentState({
        topics: [salesTopic, supportTopic],
        // Ids apart from the session the chat windows of the agent load.
        waitingQueues: [
          { topic: salesTopic, sessions: [chatSession(11, { topic: salesTopic })] },
          { topic: supportTopic, sessions: [chatSession(12)] },
        ],
        runningSessions: [runningSession(4, currentAgent), runningSession(5, currentAgent)],
      })

      const view = await visitView('/chat')

      await openPopover(view, 'Show waiting customers')

      const buttons = await view.findAllByRole('button', { name: 'Accept next' })

      expect(buttons).toHaveLength(2)

      await waitFor(() => buttons.forEach((button) => expect(button).toBeDisabled()))

      expect(
        view.getAllByText('You have reached the maximum number of concurrent chats.'),
      ).toHaveLength(1)

      buttons.forEach((button) =>
        expect(button).toHaveAccessibleDescription(
          'You have reached the maximum number of concurrent chats.',
        ),
      )
    })

    it('does not count the conversations of other agents against the limit', async () => {
      mockChatPreferences({ maxWindows: 1 })
      mockAgentState({
        ...severalTopics(waitingSessions(1)),
        runningSessions: [runningSession(4, colleague)],
      })

      const view = await visitView('/chat')

      await openPopover(view, 'Show waiting customers')

      expect(await view.findByRole('button', { name: 'Accept next' })).toBeEnabled()
    })

    it('tells the agent when the customer was taken meanwhile', async () => {
      mockAgentState(severalTopics(waitingSessions(1)))
      mockChatSessionAcceptMutation({
        chatSessionAccept: {
          session: null,
          errors: [{ __typename: 'UserError', message: 'No session available.', field: null }],
        },
      })

      const view = await visitView('/chat')

      await openPopover(view, 'Show waiting customers')
      await view.events.click(await view.findByRole('button', { name: 'Accept next' }))

      expect(await view.findByRole('alert')).toHaveTextContent('No session available.')
    })
  })

  describe('active chat sessions', () => {
    it('lists them with the agent who runs them', async () => {
      mockAgentState({
        runningSessions: [
          runningSession(4, currentAgent),
          chatSession(5, { state: EnumChatSessionState.Running, user: colleague }),
        ],
      })

      const view = await visitView('/chat')
      await openPopover(view, 'Show active chat sessions')

      expect(await view.findByText('Support #4')).toBeInTheDocument()
      expect(view.getByText('Support #5')).toBeInTheDocument()
      expect(view.getAllByText('Agent')).toHaveLength(2)
      expect(view.getByText('Chat Agent')).toBeInTheDocument()
      expect(view.getByText('Other Agent')).toBeInTheDocument()
    })

    it('lists them newest first', async () => {
      mockAgentState({
        runningSessions: [
          chatSession(4, {
            state: EnumChatSessionState.Running,
            user: currentAgent,
            createdAt: '2026-11-03T11:10:00Z',
          }),
          chatSession(5, {
            state: EnumChatSessionState.Running,
            user: colleague,
            createdAt: '2026-11-03T11:30:00Z',
          }),
        ],
      })

      const view = await visitView('/chat')
      await openPopover(view, 'Show active chat sessions')

      const list = (await view.findByText('Support #4')).closest('ul') as HTMLElement

      expect(
        within(list)
          .getAllByRole('listitem')
          .map((row) => row.textContent),
      ).toEqual([expect.stringContaining('Support #5'), expect.stringContaining('Support #4')])
    })

    it('composes the name of an agent whose full name is not readable', async () => {
      mockApplicationConfig({ user_name_format: 'last_first_comma' })
      mockAgentState({
        runningSessions: [
          chatSession(5, {
            state: EnumChatSessionState.Running,
            user: { ...colleague, fullname: null },
          }),
        ],
      })

      const view = await visitView('/chat')
      await openPopover(view, 'Show active chat sessions')

      expect(await view.findByText('Agent, Other')).toBeInTheDocument()
    })

    it('says so when no chat is running', async () => {
      mockAgentState()

      const view = await visitView('/chat')
      await openPopover(view, 'Show active chat sessions')

      expect(await view.findByText('No active chat sessions')).toBeInTheDocument()
    })
  })

  describe('active agents', () => {
    it('lists them by name', async () => {
      mockAgentState({ availableAgents: [currentAgent, colleague] })

      const view = await visitView('/chat')
      await openPopover(view, 'Show active agents')

      expect(await view.findByText('Chat Agent')).toBeInTheDocument()
      expect(view.getByText('Other Agent')).toBeInTheDocument()
    })

    it('composes the name of an agent whose full name is not readable', async () => {
      mockApplicationConfig({ user_name_format: 'last_first_comma' })
      mockAgentState({ availableAgents: [{ ...colleague, fullname: null }] })

      const view = await visitView('/chat')
      await openPopover(view, 'Show active agents')

      expect(await view.findByText('Agent, Other')).toBeInTheDocument()
    })

    it('says so when nobody is available', async () => {
      mockAgentState({ availableAgents: [] })

      const view = await visitView('/chat')
      await openPopover(view, 'Show active agents')

      expect(await view.findByText('No available agents')).toBeInTheDocument()
    })
  })
})
