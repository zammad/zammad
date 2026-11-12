// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { defineComponent, h } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent, { initializePiniaStore } from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { useSessionStore } from '#shared/stores/session.ts'

import {
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  mockChatPreferences,
  preferencesTopic,
  salesTopic,
  supportTopic,
} from '#desktop/entities/chat/__tests__/mocks/chat-mocks.ts'
import { ChatAgentAvailabilityUpdateDocument } from '#desktop/entities/chat/graphql/mutations/chatAgentAvailabilityUpdate.api.ts'
import { ChatPreferencesUpdateDocument } from '#desktop/entities/chat/graphql/mutations/chatPreferencesUpdate.api.ts'
import {
  mockChatPreferencesUpdateMutation,
  waitForChatPreferencesUpdateMutationCalls,
} from '#desktop/entities/chat/graphql/mutations/chatPreferencesUpdate.mocks.ts'
import { ChatAgentStateDocument } from '#desktop/entities/chat/graphql/queries/chatAgentState.api.ts'
import { ChatPreferencesDocument } from '#desktop/entities/chat/graphql/queries/chatPreferences.api.ts'
import {
  mockChatPreferencesQuery,
  waitForChatPreferencesQueryCalls,
} from '#desktop/entities/chat/graphql/queries/chatPreferences.mocks.ts'
import { useChatPreferencesStore } from '#desktop/entities/chat/stores/chatPreferences.ts'

import ChatSettingsFlyout from '../ChatSettingsFlyout.vue'

const FLYOUT_NAME = 'chat-settings'

const storedPreferences = {
  maxWindows: 6,
  alternativeName: 'Erika',
  avatarEnabled: true,
  topics: [
    preferencesTopic(supportTopic, true, ['Hello, I am Erika', 'Good day']),
    preferencesTopic(salesTopic, false),
  ],
}

// The toolbar keeps the preferences loaded while the page is open, and nothing pushes a change made elsewhere.
const PageHost = defineComponent({
  setup() {
    useChatPreferencesStore()

    return () => h('div')
  },
})

const loadPreferencesForThePage = async () => {
  initializePiniaStore()
  renderComponent(PageHost, { store: true })
  await waitForChatPreferencesQueryCalls()
}

const renderFlyout = () => {
  initializePiniaStore()

  return renderComponent(ChatSettingsFlyout, {
    props: { name: FLYOUT_NAME },
    form: true,
    router: true,
    store: true,
    global: {
      stubs: {
        teleport: true,
      },
    },
  })
}

const submit = async (wrapper: ReturnType<typeof renderFlyout>) => {
  const limit = await wrapper.findByLabelText('Max. concurrent chats')

  await waitFor(() => expect(limit).toBeVisible())

  return limit
}

describe('ChatSettingsFlyout', () => {
  beforeEach(() => {
    mockChatAgent()
    useSessionStore().user!.image = 'agent-avatar.png'
    mockChatEnabled()
    mockChatPreferences(storedPreferences)
    mockAgentState({ active: true })
  })

  it('shows the stored preferences', async () => {
    const wrapper = renderFlyout()

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent('Chat settings')

    expect(await wrapper.findByLabelText('Max. concurrent chats')).toHaveValue(6)
    expect(wrapper.getByLabelText('Alternative name')).toHaveValue('Erika')
    expect(wrapper.getByLabelText('Avatar')).toBeChecked()
    expect(wrapper.getByLabelText('Avatar (Chat Agent)')).toBeInTheDocument()
    expect(wrapper.getByText('Topics')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Support')).toBeChecked()
    expect(wrapper.getByLabelText('Sales')).not.toBeChecked()

    // Only Support has welcome messages, so only its list is there; each topic can add one.
    const [supportMessages] = await wrapper.findAllByRole('list', {
      name: 'Welcome messages',
    })

    expect(within(supportMessages).getAllByRole('listitem')).toHaveLength(2)
    expect(supportMessages).toHaveTextContent('Hello, I am Erika')
    expect(supportMessages).toHaveTextContent('Good day')
    expect(wrapper.getAllByRole('button', { name: 'Add welcome message' })).toHaveLength(2)
    // Support has some and says what they are for, Sales has none yet.
    expect(wrapper.getAllByText('No welcome messages added yet.')).toHaveLength(1)
    expect(
      wrapper.getAllByText('One of them is sent at random when you accept a chat.'),
    ).toHaveLength(1)
  })

  it('offers no avatar while the agent has not uploaded a picture, only the way to set one up', async () => {
    useSessionStore().user!.image = null
    mockChatPreferencesUpdateMutation({
      chatPreferencesUpdate: { preferences: storedPreferences, errors: null },
    })

    const wrapper = renderFlyout()

    const avatar = await wrapper.findByLabelText('Avatar')

    // Stored as on, but there is nothing to show.
    expect(avatar).not.toBeChecked()
    expect(avatar).toHaveAttribute('aria-disabled', 'true')
    expect(avatar).toHaveAccessibleDescription(
      'No avatar image yet. Upload one in your personal settings.',
    )
    // The initials are no preview of what the customer sees.
    expect(wrapper.queryByLabelText('Avatar (Chat Agent)')).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit' }))

    const calls = await waitForChatPreferencesUpdateMutationCalls()

    // A picture uploaded later is not shown until the agent turns it on.
    expect(calls.at(-1)?.variables.preferences.avatarEnabled).toBe(false)
  })

  it('removes a welcome message only when the form is submitted', async () => {
    mockChatPreferencesUpdateMutation({
      chatPreferencesUpdate: { preferences: storedPreferences, errors: null },
    })

    const wrapper = renderFlyout()

    await submit(wrapper)

    const goodDay = within(wrapper.getByRole('list', { name: 'Welcome messages' })).getAllByRole(
      'listitem',
    )[1]

    await wrapper.events.click(within(goodDay).getByRole('button', { name: 'Action menu button' }))
    await wrapper.events.click(
      await wrapper.findByRole('button', { name: 'Remove welcome message' }),
    )

    expect(wrapper.queryByText('Good day')).not.toBeInTheDocument()
    expect(getGraphQLMockCalls(ChatPreferencesUpdateDocument)).toHaveLength(0)

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit' }))

    const calls = await waitForChatPreferencesUpdateMutationCalls()

    expect(calls.at(-1)?.variables.preferences.topics[0]).toEqual({
      topicId: supportTopic.id,
      active: true,
      phrases: ['Hello, I am Erika'],
    })
  })

  it('starts from what is stored when it opens, not from what the page loaded earlier', async () => {
    await loadPreferencesForThePage()

    mockChatPreferences({
      ...storedPreferences,
      maxWindows: 9,
      alternativeName: 'Changed elsewhere',
    })

    const wrapper = renderFlyout()

    expect(await wrapper.findByLabelText('Max. concurrent chats')).toHaveValue(9)
    expect(wrapper.getByLabelText('Alternative name')).toHaveValue('Changed elsewhere')
  })

  it('shows an error instead of what the page loaded earlier when the read fails, until a retry succeeds', async () => {
    await loadPreferencesForThePage()

    mockChatPreferencesQuery(() => Promise.reject(new Error('Network down')))

    const wrapper = renderFlyout()

    expect(await wrapper.findByText('The chat settings could not be loaded.')).toBeInTheDocument()
    expect(wrapper.queryByLabelText('Max. concurrent chats')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Submit' })).not.toBeInTheDocument()

    mockChatPreferences({ ...storedPreferences, maxWindows: 9 })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Try again' }))

    expect(await wrapper.findByLabelText('Max. concurrent chats')).toHaveValue(9)
    expect(wrapper.getByRole('button', { name: 'Submit' })).toBeInTheDocument()
  })

  it('saves the changes in the shape of the mutation and reads the state again', async () => {
    mockChatPreferencesUpdateMutation({
      chatPreferencesUpdate: { preferences: storedPreferences, errors: null },
    })

    const wrapper = renderFlyout()

    const limit = await submit(wrapper)

    await wrapper.events.clear(limit)
    await wrapper.events.type(limit, '8')
    await wrapper.events.click(wrapper.getByLabelText('Avatar'))
    await wrapper.events.click(wrapper.getByLabelText('Sales'))

    // A new line opens for typing; one given up empty is not kept.
    const addToSales = () =>
      wrapper.events.click(wrapper.getAllByRole('button', { name: 'Add welcome message' })[1])

    await addToSales()
    await wrapper.events.keyboard('Good afternoon{Enter}')
    await addToSales()
    await wrapper.events.keyboard('Welcome{Enter}')
    await addToSales()
    await wrapper.events.keyboard('{Escape}')

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit' }))

    const calls = await waitForChatPreferencesUpdateMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      preferences: {
        maxWindows: 8,
        alternativeName: 'Erika',
        avatarEnabled: false,
        topics: [
          { topicId: supportTopic.id, active: true, phrases: ['Hello, I am Erika', 'Good day'] },
          { topicId: salesTopic.id, active: true, phrases: ['Good afternoon', 'Welcome'] },
        ],
      },
    })

    // The preferences are not pushed, and the page does not wait for the push of the state.
    await waitFor(() =>
      expect(getGraphQLMockCalls(ChatAgentStateDocument).length).toBeGreaterThan(1),
    )
    expect(getGraphQLMockCalls(ChatPreferencesDocument).length).toBeGreaterThan(1)
  })

  it('stops a limit out of range before anything is sent', async () => {
    const wrapper = renderFlyout()

    const limit = await submit(wrapper)

    await wrapper.events.clear(limit)
    await wrapper.events.type(limit, '21')
    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit' }))

    await waitFor(() => expect(limit).toBeInvalid())
    expect(getGraphQLMockCalls(ChatPreferencesUpdateDocument)).toHaveLength(0)
  })

  // The server switches an agent off who has no topic left, in the same write.
  it('sends no availability write of its own when no topic stays enabled', async () => {
    mockChatPreferencesUpdateMutation({
      chatPreferencesUpdate: { preferences: storedPreferences, errors: null },
    })

    const wrapper = renderFlyout()

    await submit(wrapper)

    await wrapper.events.click(wrapper.getByLabelText('Support'))
    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit' }))

    const calls = await waitForChatPreferencesUpdateMutationCalls()

    expect(calls.at(-1)?.variables.preferences.topics).toEqual([
      { topicId: supportTopic.id, active: false, phrases: ['Hello, I am Erika', 'Good day'] },
      { topicId: salesTopic.id, active: false, phrases: [] },
    ])

    await waitFor(() =>
      expect(getGraphQLMockCalls(ChatAgentStateDocument).length).toBeGreaterThan(1),
    )
    expect(getGraphQLMockCalls(ChatAgentAvailabilityUpdateDocument)).toHaveLength(0)
  })
})
