// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref, type Ref } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import TicketKnowledgeBaseAiDraftFlyout from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketRelatedKnowledge/TicketKnowledgeBaseAiDraftFlyout.vue'
import {
  mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation,
  mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationError,
  waitForTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/ticketAIAssistanceEnqueueKnowledgeBaseAnswer.mocks.ts'
import { TicketAiRelatedKnowledgeBaseAnswersDocument } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.api.ts'
import {
  mockTicketAiRelatedKnowledgeBaseAnswersQuery,
  mockTicketAiRelatedKnowledgeBaseAnswersQueryError,
  waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls,
} from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.mocks.ts'
import { getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/ticketAIRelatedKnowledgeBaseAnswersUpdates.mocks.ts'

const ticketId = convertToGraphQLId('Ticket', 1)

// The score arrives as a ratio and is turned into a percentage by the composable.
const relatedAnswer = (id: number, title: string, score = 0.88) => ({
  score,
  translation: {
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
    title,
    visibility: EnumKnowledgeBaseVisibility.Published,
    content: { bodyExcerpt: 'Steps to solve the issue.' },
    answer: {
      id: convertToGraphQLId('KnowledgeBase::Answer', id),
      archivedAt: null,
      publishedAt: '2024-01-01T00:00:00Z',
      category: {
        id: convertToGraphQLId('KnowledgeBase::Category', 1),
        title: 'Account',
        knowledgeBase: { id: convertToGraphQLId('KnowledgeBase', 1) },
      },
    },
    kbLocale: { systemLocale: { locale: 'en-us', name: 'English' } },
  },
})

const mockSuggestedAnswers = (answers: ReturnType<typeof relatedAnswer>[], pending = false) =>
  mockTicketAiRelatedKnowledgeBaseAnswersQuery({
    ticketAIRelatedKnowledgeBaseAnswers: { pending, answers },
  })

// The active sidebar arrives as a getter, so the flyout keeps up with a sidebar switch while it is
//   open — that is what hands the ownership of the live search over to it.
const renderFlyout = (activeSidebar: Ref<string> = ref('information')) =>
  renderComponent(TicketKnowledgeBaseAiDraftFlyout, {
    props: {
      name: 'knowledge-base-ai-draft',
      ticketId,
      activeSidebar: () => activeSidebar.value,
    },
    router: true,
    routerRoutes: [
      { path: '/', name: 'Root', component: { template: '<div />' } },
      {
        path: '/knowledge-base/:localeCode/category/:categoryInternalId',
        name: 'KnowledgeBaseCategory',
        component: { template: '<div />' },
      },
      // Tags link into the detailed search.
      { path: '/search/:searchTerm?', name: 'Search', component: { template: '<div />' } },
    ],
    store: true,
    flyout: true,
  })

describe('TicketKnowledgeBaseAiDraftFlyout', () => {
  const notifications = useNotifications()

  vi.spyOn(notifications, 'notify')

  beforeEach(() => {
    vi.clearAllMocks()
    mockPermissions(['ticket.agent', 'knowledge_base.editor'])
    // The sidebar list is visible, so it owns the live search (see the query wiring below).
    mockApplicationConfig({ ai_provider: true })
  })

  it('shows the header title', async () => {
    mockSuggestedAnswers([])

    const wrapper = renderFlyout()

    expect(
      wrapper.getByRole('heading', {
        name: 'Generate knowledge base answer from this ticket',
        level: 2,
      }),
    ).toBeInTheDocument()

    await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()
  })

  it('renders each suggested answer with its score, excerpt and attributes', async () => {
    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password', 0.88)])

    const wrapper = renderFlyout()

    expect(await wrapper.findByText('Reset your password')).toBeInTheDocument()
    expect(wrapper.getByText('88%')).toBeInTheDocument()
    expect(wrapper.getByText('Steps to solve the issue.')).toBeInTheDocument()
    expect(wrapper.getByText('Account')).toBeInTheDocument()
    expect(wrapper.getByText('English')).toBeInTheDocument()

    expect(wrapper.getByText('Reset your password').closest('a')).toHaveAttribute(
      'href',
      expect.stringContaining(
        `#knowledge_base/${getIdFromGraphQLId(convertToGraphQLId('KnowledgeBase', 1))}/locale/en-us/answer/${getIdFromGraphQLId(
          convertToGraphQLId('KnowledgeBase::Answer', 1),
        )}`,
      ),
    )
    expect(wrapper.getByText('Reset your password').closest('a')).toHaveAttribute(
      'target',
      '_blank',
    )
  })

  it('shows the searching skeleton while the embedding is still being generated', async () => {
    mockSuggestedAnswers([], true)

    const wrapper = renderFlyout()

    expect(await wrapper.findByLabelText('Searching for related answers…')).toBeInTheDocument()
    // Three answer-shaped placeholders, so the box does not jump once the answers arrive.
    expect(wrapper.getAllByRole('listitem')).toHaveLength(3)
  })

  it('clears the BETA UI switch when an answer link is followed', async () => {
    localStorage.setItem('beta-ui-switch', 'true')

    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    const wrapper = renderFlyout()

    await wrapper.events.click(await wrapper.findByText('Reset your password'))

    // Otherwise the legacy answer view would redirect straight back to the new app.
    await vi.waitFor(() => expect(localStorage.getItem('beta-ui-switch')).toBeNull())
  })

  it('shows the error detail and offers a retry when the search itself fails', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQueryError('boom', {
      type: GraphQLErrorTypes.UnknownError,
    })

    const wrapper = renderFlyout()

    expect(
      await wrapper.findByText(
        'The suggestions could not be generated. Please try again later or contact your administrator.',
      ),
    ).toBeInTheDocument()
    expect(wrapper.getByText('API server error: boom')).toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Retry' })).toBeInTheDocument()

    // The suggestion list is replaced by the error, not shown alongside it.
    expect(wrapper.queryByText('AI suggested knowledge')).not.toBeInTheDocument()
  })

  it('clears an embed error and re-runs the search on retry', async () => {
    // Only reachable when the flyout owns the subscriptions, i.e. with the sidebar list hidden.
    mockApplicationConfig({ ai_provider: false })

    mockSuggestedAnswers([], true)

    const wrapper = renderFlyout()
    await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()

    await getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler().trigger({
      ticketAIRelatedKnowledgeBaseAnswersUpdates: { ticketId, error: 'embedding failed' },
    })

    expect(await wrapper.findByText('API server error: embedding failed')).toBeInTheDocument()

    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Retry' }))

    expect(await wrapper.findByText('Reset your password')).toBeInTheDocument()
    expect(wrapper.queryByText('API server error: embedding failed')).not.toBeInTheDocument()
  })

  it('reads from the cache without a second request while the sidebar list owns the search', async () => {
    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    // Prime the cache the way the sidebar list would have.
    const primer = renderFlyout()
    await primer.findByText('Reset your password')
    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(1)

    const wrapper = renderFlyout()

    expect(await wrapper.findAllByText('Reset your password')).toHaveLength(2)
    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(1)
    // The sidebar list holds the subscriptions; the flyout only reads.
    expect(getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler()).toBeUndefined()
  })

  it('drives the search itself when the sidebar list is not shown', async () => {
    mockApplicationConfig({ ai_provider: false })

    mockSuggestedAnswers([], true)

    const wrapper = renderFlyout()

    expect(await wrapper.findByLabelText('Searching for related answers…')).toBeInTheDocument()

    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    // Without the sidebar list around, only the flyout’s own ping subscription can resolve this.
    await getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler().trigger({
      ticketAIRelatedKnowledgeBaseAnswersUpdates: { ticketId, error: null },
    })

    expect(await wrapper.findAllByText('Reset your password')).not.toHaveLength(0)
  })

  it('drives the search itself when the information sidebar is not selected', async () => {
    mockSuggestedAnswers([], true)

    const primer = renderFlyout()

    expect(await primer.findByLabelText('Searching for related answers…')).toBeInTheDocument()
    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(1)

    mockSuggestedAnswers([], true)

    const wrapper = renderFlyout(ref('customer'))

    expect(await wrapper.findByLabelText('Searching for related answers…')).toBeInTheDocument()
    await waitFor(() =>
      expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(2),
    )

    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    await getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler().trigger({
      ticketAIRelatedKnowledgeBaseAnswersUpdates: { ticketId, error: null },
    })

    expect(await wrapper.findAllByText('Reset your password')).not.toHaveLength(0)
  })

  it('takes over the search when the sidebar is switched away while the flyout is open', async () => {
    const activeSidebar = ref('information')

    mockSuggestedAnswers([], true)

    const wrapper = renderFlyout(activeSidebar)

    expect(await wrapper.findByLabelText('Searching for related answers…')).toBeInTheDocument()
    // The sidebar list still owns the live result, so the flyout only reads from its cache entry.
    expect(getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler()).toBeUndefined()

    activeSidebar.value = 'customer'

    // The list is gone, so the flyout has to drive the search itself from now on.
    await waitFor(() =>
      expect(getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler()).toBeDefined(),
    )

    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    // Without the list around, only the flyout’s own ping subscription can resolve the pending
    //   embedding — a snapshotted sidebar would leave it spinning forever.
    await getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler().trigger({
      ticketAIRelatedKnowledgeBaseAnswersUpdates: { ticketId, error: null },
    })

    expect(await wrapper.findAllByText('Reset your password')).not.toHaveLength(0)
  })

  it('triggers the generation mutation and shows an info notification when Generate is clicked', async () => {
    mockSuggestedAnswers([])

    mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation({
      ticketAIAssistanceEnqueueKnowledgeBaseAnswer: {
        success: true,
      },
    })

    const wrapper = renderFlyout()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Generate' }))

    await waitFor(() =>
      expect(notifications.notify).toHaveBeenCalledWith({
        id: 'ticket-ai-knowledge-base-answers-notification',
        message:
          'A related knowledge base answer is being generated. You will be notified once the draft is ready.',
        type: 'info',
        durationMS: 8000,
      }),
    )

    const calls = await waitForTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationCalls()
    expect(calls.at(-1)?.variables).toEqual({ ticketId })
  })

  it('shows the error inside the flyout when the generation request fails', async () => {
    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationError('Generation failed', {
      type: GraphQLErrorTypes.UnknownError,
    })

    const wrapper = renderFlyout()

    // The flyout stays open on failure, so the error is shown in place instead of as a notification.
    await wrapper.events.click(await wrapper.findByRole('button', { name: 'Generate' }))

    expect(await wrapper.findByRole('alert')).toHaveTextContent('Generation failed')
    expect(notifications.notify).not.toHaveBeenCalled()

    // The suggestion list is replaced by the error, and generating cannot be retried.
    expect(wrapper.queryByText('Reset your password')).not.toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Generate' })).toBeDisabled()
  })

  it('shows empty message when no answers are found', async () => {
    mockSuggestedAnswers([])

    const wrapper = renderFlyout()

    expect(
      await wrapper.findByText(
        'No existing knowledge base answers match this topic. Generate a new answer to continue.',
      ),
    ).toBeInTheDocument()

    expect(
      wrapper.queryByText('None of the existing knowledge base answers fit your ticket?'),
    ).not.toBeInTheDocument()

    expect(
      wrapper.queryByText(
        'Before creating a new knowledge base answer, please check whether an existing answer already covers the solution for this ticket.',
      ),
    ).not.toBeInTheDocument()
  })
})
