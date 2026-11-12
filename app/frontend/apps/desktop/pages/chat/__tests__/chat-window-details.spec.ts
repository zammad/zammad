// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import {
  mockTagAssignmentAddMutation,
  mockTagAssignmentAddMutationError,
  waitForTagAssignmentAddMutationCalls,
} from '#shared/entities/tags/graphql/mutations/assignment/add.mocks.ts'
import {
  mockTagAssignmentRemoveMutation,
  mockTagAssignmentRemoveMutationError,
  waitForTagAssignmentRemoveMutationCalls,
} from '#shared/entities/tags/graphql/mutations/assignment/remove.mocks.ts'
import {
  mockAutocompleteSearchTagQuery,
  waitForAutocompleteSearchTagQueryCalls,
} from '#shared/entities/tags/graphql/queries/autocompleteTags.mocks.ts'
import { EnumChatSessionState, type ChatSessionUpdatesSubscription } from '#shared/graphql/types.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  chatMessage,
  currentAgent,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  mockChatPreferences,
  mockChatSession,
  runningSession,
  salesTopic,
  supportTopic,
} from '#desktop/entities/chat/__tests__/mocks/chat-mocks.ts'
import { ChatSessionTransferDocument } from '#desktop/entities/chat/graphql/mutations/chatSessionTransfer.api.ts'
import {
  mockChatSessionTransferMutation,
  waitForChatSessionTransferMutationCalls,
} from '#desktop/entities/chat/graphql/mutations/chatSessionTransfer.mocks.ts'
import { mockChatSessionTypingMutation } from '#desktop/entities/chat/graphql/mutations/chatSessionTyping.mocks.ts'
import { getChatSessionUpdatesSubscriptionHandler } from '#desktop/entities/chat/graphql/subscriptions/chatSessionUpdates.mocks.ts'
import type { ChatConversationSession } from '#desktop/entities/chat/types.ts'

const session = runningSession(1, currentAgent)

const openWindow = async (
  overrides: Partial<ChatConversationSession> = {},
  topics = [supportTopic, salesTopic],
) => {
  const shownSession = { ...session, ...overrides }

  mockAgentState({ runningSessions: [shownSession], topics })
  mockChatSession(shownSession, [chatMessage(1, '<div>Hello</div>', '2026-11-03T11:00:00Z')])

  const view = await visitView('/chat')

  await view.findByRole('region', { name: shownSession.name ?? 'Support #1' })
  await view.findByText('Hello')

  return view
}

const openMenu = async (view: Awaited<ReturnType<typeof openWindow>>) => {
  await view.events.click(view.getByRole('button', { name: 'Additional actions' }))

  return view.findByRole('menu')
}

const openDetails = async (item: string, overrides: Partial<ChatConversationSession> = {}) => {
  const view = await openWindow(overrides)

  await view.events.click(within(await openMenu(view)).getByText(item))

  return view
}

const shownTags = (view: Awaited<ReturnType<typeof openWindow>>) =>
  within(view.getByRole('list', { name: 'Tags' }))
    .getAllByRole('listitem')
    .map((item) => item.textContent?.trim())

describe('Chat window details', () => {
  beforeEach(() => {
    mockChatAgent()
    mockChatEnabled()
    mockChatPreferences()
    mockChatSessionTypingMutation({ chatSessionTyping: { success: true, errors: null } })
  })

  it('shows the meta information alone above the thread, and hides it when done', async () => {
    const view = await openDetails('Show meta data', { dnsName: 'customer.example.com' })

    expect(view.getByText('Hello')).toBeInTheDocument()

    // The line above the thread shows the location too, so the rows are read from the list.
    const rows = within(view.getByText('Created at').closest('dl') as HTMLElement)

    expect(rows.getByText('2026-11-03 11:14')).toBeInTheDocument()
    expect(rows.getByText('GeoIP')).toBeInTheDocument()
    expect(rows.getByText('Germany, Berlin')).toBeInTheDocument()
    expect(rows.getByText('IP address')).toBeInTheDocument()
    expect(rows.getByText('203.0.113.5')).toBeInTheDocument()
    expect(rows.getByText('DNS name')).toBeInTheDocument()
    expect(rows.getByText('customer.example.com')).toBeInTheDocument()

    expect(view.queryByLabelText('Transfer to another topic')).not.toBeInTheDocument()
    expect(view.queryByText('Tags')).not.toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'OK' }))

    expect(view.queryByText('Created at')).not.toBeInTheDocument()
    expect(view.getByText('Hello')).toBeInTheDocument()
  })

  it('shows only the start when nothing else was recorded', async () => {
    const view = await openDetails('Show meta data', {
      remoteIp: null,
      dnsName: null,
      geoIp: null,
    })

    expect(view.getByText('Created at')).toBeInTheDocument()
    expect(view.queryByText('GeoIP')).not.toBeInTheDocument()
    expect(view.queryByText('IP address')).not.toBeInTheDocument()
    expect(view.queryByText('DNS name')).not.toBeInTheDocument()
  })

  it('switches to another section from the menu while one is open', async () => {
    const view = await openDetails('Show meta data')

    expect(view.getByText('Created at')).toBeInTheDocument()

    await view.events.click(within(await openMenu(view)).getByText('Manage chat tags'))

    expect(view.queryByText('Created at')).not.toBeInTheDocument()
    expect(view.getByText('No tags added yet.')).toBeInTheDocument()
  })

  it('gives the focus back to the menu when the button that had it closes the details', async () => {
    const view = await openDetails('Show meta data')

    view.getByRole('button', { name: 'OK' }).focus()
    await view.events.keyboard('{Enter}')

    expect(view.queryByText('Created at')).not.toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Additional actions' })).toHaveFocus()

    await view.events.click(within(await openMenu(view)).getByText('Transfer to another topic'))

    view.getByRole('button', { name: 'Cancel' }).focus()
    await view.events.keyboard('{Enter}')

    expect(view.queryByLabelText('Transfer to another topic')).not.toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Additional actions' })).toHaveFocus()
  })

  describe('tagging', () => {
    it('shows the tags and removes one right away', async () => {
      mockTagAssignmentRemoveMutation({ tagAssignmentRemove: { success: true, errors: null } })

      const view = await openDetails('Manage chat tags', { tags: ['vip', 'billing'] })

      expect(view.getByRole('list', { name: 'Tags' })).toHaveTextContent('vip')
      expect(view.getByRole('list', { name: 'Tags' })).toHaveTextContent('billing')

      await view.events.click(view.getAllByRole('button', { name: 'Remove this tag' })[0])

      const calls = await waitForTagAssignmentRemoveMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ objectId: session.id, tag: 'vip' })
      expect(view.getByRole('list', { name: 'Tags' })).not.toHaveTextContent('vip')
    })

    it('adds a picked tag right away', async () => {
      mockAutocompleteSearchTagQuery({
        autocompleteSearchTag: [
          { __typename: 'AutocompleteSearchEntry', value: 'billing', label: 'billing' },
        ],
      })
      mockTagAssignmentAddMutation({ tagAssignmentAdd: { success: true, errors: null } })

      const view = await openDetails('Manage chat tags')

      expect(view.getByText('No tags added yet.')).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Add tag' }))
      await waitForAutocompleteSearchTagQueryCalls()
      await view.events.click(view.getByRole('option', { name: 'billing' }))

      const calls = await waitForTagAssignmentAddMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ objectId: session.id, tag: 'billing' })
      expect(await view.findByRole('list', { name: 'Tags' })).toHaveTextContent('billing')
    })

    it('puts a removed tag back when the server keeps it, and tells the agent', async () => {
      mockTagAssignmentRemoveMutationError('Not authorized', {
        type: GraphQLErrorTypes.Forbidden,
      })

      const view = await openDetails('Manage chat tags', { tags: ['vip', 'billing'] })

      await view.events.click(view.getAllByRole('button', { name: 'Remove this tag' })[0])

      expect(await view.findByRole('alert')).toHaveTextContent('The tag could not be removed.')
      await waitFor(() => expect(shownTags(view)).toEqual(['vip', 'billing']))
    })

    it('takes an added tag back off when the server does not store it, and tells the agent', async () => {
      mockAutocompleteSearchTagQuery({
        autocompleteSearchTag: [
          { __typename: 'AutocompleteSearchEntry', value: 'billing', label: 'billing' },
        ],
      })
      mockTagAssignmentAddMutationError('Not authorized', {
        type: GraphQLErrorTypes.Forbidden,
      })

      const view = await openDetails('Manage chat tags', { tags: ['vip'] })

      await view.events.click(view.getByRole('button', { name: 'Add tag' }))
      await waitForAutocompleteSearchTagQueryCalls()
      await view.events.click(view.getByRole('option', { name: 'billing' }))

      expect(await view.findByRole('alert')).toHaveTextContent('The tag could not be added.')
      await waitFor(() => expect(shownTags(view)).toEqual(['vip']))
    })

    it('puts back only the removal that failed, and still removes the tag removed meanwhile', async () => {
      let failVipRemoval!: (error: Error) => void

      mockTagAssignmentRemoveMutation(({ tag }) =>
        tag === 'vip'
          ? new Promise((_resolve, reject) => {
              failVipRemoval = reject
            })
          : { tagAssignmentRemove: { success: true, errors: null } },
      )

      const view = await openDetails('Manage chat tags', { tags: ['vip', 'billing'] })

      await view.events.click(view.getAllByRole('button', { name: 'Remove this tag' })[0])
      await waitForTagAssignmentRemoveMutationCalls()
      await view.events.click(view.getByRole('button', { name: 'Remove this tag' }))

      expect(view.getByText('No tags added yet.')).toBeInTheDocument()

      // The second removal waits until the first one is answered.
      expect(await waitForTagAssignmentRemoveMutationCalls()).toHaveLength(1)

      failVipRemoval(new Error('Connection lost'))

      expect(await view.findByText('The tag could not be removed.')).toBeInTheDocument()
      expect(await view.findByText('Tag removed successfully.')).toBeInTheDocument()
      expect(shownTags(view)).toEqual(['vip'])

      const calls = await waitForTagAssignmentRemoveMutationCalls()

      expect(calls.map((call) => call.variables.tag)).toEqual(['vip', 'billing'])
    })

    it('takes back only the addition that failed, and still removes the tag removed meanwhile', async () => {
      let failBillingAddition!: (error: Error) => void

      mockAutocompleteSearchTagQuery({
        autocompleteSearchTag: [
          { __typename: 'AutocompleteSearchEntry', value: 'billing', label: 'billing' },
        ],
      })
      mockTagAssignmentAddMutation(
        () =>
          new Promise((_resolve, reject) => {
            failBillingAddition = reject
          }),
      )
      mockTagAssignmentRemoveMutation({ tagAssignmentRemove: { success: true, errors: null } })

      const view = await openDetails('Manage chat tags', { tags: ['vip'] })

      await view.events.click(view.getByRole('button', { name: 'Add tag' }))
      await waitForAutocompleteSearchTagQueryCalls()
      await view.events.click(view.getByRole('option', { name: 'billing' }))
      await waitForTagAssignmentAddMutationCalls()
      await view.events.click(view.getAllByRole('button', { name: 'Remove this tag' })[0])

      expect(shownTags(view)).toEqual(['billing'])

      failBillingAddition(new Error('Connection lost'))

      expect(await view.findByText('The tag could not be added.')).toBeInTheDocument()
      expect(await view.findByText('Tag removed successfully.')).toBeInTheDocument()
      expect(view.getByText('No tags added yet.')).toBeInTheDocument()
    })
  })

  describe('transferring', () => {
    it('moves the conversation to the picked topic once the agent is done, and closes the window', async () => {
      mockChatSessionTransferMutation({
        chatSessionTransfer: {
          session: { ...session, state: EnumChatSessionState.Waiting, topic: salesTopic },
          errors: null,
        },
      })

      const view = await openDetails('Transfer to another topic')

      await view.events.click(view.getByLabelText('Transfer to another topic'))
      await view.events.click(await view.findByRole('option', { name: 'Sales' }))

      expect(getGraphQLMockCalls(ChatSessionTransferDocument)).toHaveLength(0)

      await view.events.click(view.getByRole('button', { name: 'Transfer chat' }))

      const calls = await waitForChatSessionTransferMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ sessionId: session.id, topicId: salesTopic.id })
      expect(view.queryByRole('region', { name: 'Support #1' })).not.toBeInTheDocument()
    })

    it('transfers only with a topic, and leaves the conversation where it is when cancelled', async () => {
      const view = await openDetails('Transfer to another topic')

      expect(view.getByRole('button', { name: 'Transfer chat' })).toBeDisabled()

      await view.events.click(view.getByLabelText('Transfer to another topic'))
      await view.events.click(await view.findByRole('option', { name: 'Sales' }))

      expect(view.getByRole('button', { name: 'Transfer chat' })).toBeEnabled()

      await view.events.click(view.getByRole('button', { name: 'Clear selection' }))

      expect(view.getByRole('button', { name: 'Transfer chat' })).toBeDisabled()

      await view.events.click(view.getByRole('button', { name: 'Cancel' }))

      expect(getGraphQLMockCalls(ChatSessionTransferDocument)).toHaveLength(0)
      expect(view.queryByLabelText('Transfer to another topic')).not.toBeInTheDocument()
      expect(view.getByText('Hello')).toBeInTheDocument()
    })

    it('forgets a picked topic when the agent switches to another section and back', async () => {
      const view = await openDetails('Transfer to another topic')

      await view.events.click(view.getByLabelText('Transfer to another topic'))
      await view.events.click(await view.findByRole('option', { name: 'Sales' }))

      await view.events.click(within(await openMenu(view)).getByText('Manage chat tags'))
      await view.events.click(within(await openMenu(view)).getByText('Transfer to another topic'))

      expect(view.getByRole('button', { name: 'Transfer chat' })).toBeDisabled()
      expect(getGraphQLMockCalls(ChatSessionTransferDocument)).toHaveLength(0)
    })

    it('cannot transfer once the chat closed while the panel is open', async () => {
      const view = await openDetails('Transfer to another topic')

      await view.events.click(view.getByLabelText('Transfer to another topic'))
      await view.events.click(await view.findByRole('option', { name: 'Sales' }))

      expect(view.getByRole('button', { name: 'Transfer chat' })).toBeEnabled()

      await getChatSessionUpdatesSubscriptionHandler().trigger(
        nullableMock<ChatSessionUpdatesSubscription>({
          chatSessionUpdates: {
            __typename: 'ChatSessionUpdatesPayload',
            message: null,
            typing: null,
            notice: null,
            leftBy: null,
            closedBy: 'Anonymous',
          },
        }),
      )
      await waitForNextTick()

      expect(view.getByRole('button', { name: 'Transfer chat' })).toBeDisabled()
      expect(view.getByLabelText('Transfer to another topic')).toBeDisabled()
      expect(getGraphQLMockCalls(ChatSessionTransferDocument)).toHaveLength(0)
    })

    it('offers no transfer when there is no other topic', async () => {
      const view = await openWindow({}, [supportTopic])

      const menu = await openMenu(view)

      expect(within(menu).getByText('Manage chat tags')).toBeInTheDocument()
      expect(within(menu).queryByText('Transfer to another topic')).not.toBeInTheDocument()
    })

    it('offers no transfer once the conversation is over, and tells why', async () => {
      const view = await openWindow({ state: EnumChatSessionState.Closed })

      const item = within(await openMenu(view)).getByRole('button', {
        name: 'Transfer to another topic',
      })

      expect(item).toHaveAttribute('aria-disabled', 'true')
      expect(item).toHaveAttribute('aria-description', 'This conversation is closed.')

      await view.events.click(item)

      expect(view.queryByLabelText('Transfer to another topic')).not.toBeInTheDocument()
      expect(getGraphQLMockCalls(ChatSessionTransferDocument)).toHaveLength(0)
    })
  })
})
