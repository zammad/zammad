// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

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
const relatedAnswer = (
  id: number,
  title: string,
  score = 0.88,
  visibility = EnumKnowledgeBaseVisibility.Published,
) => ({
  score,
  translation: {
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
    title,
    visibility,
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

// The opener hands the ticket over, since a flyout cannot inject it.
const ticketArticleCount = ref(1)

const ticket = computed(() => ({ id: ticketId, articleCount: ticketArticleCount.value }))

const renderFlyout = () =>
  renderComponent(TicketKnowledgeBaseAiDraftFlyout, {
    props: {
      name: 'knowledge-base-ai-draft',
      ticket: ticket.value,
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
    // The relevance score is the only thing the flyout gates, and it goes by permission.
    mockPermissions(['ticket.agent', 'knowledge_base.editor', 'admin.ai_knowledge_base'])
    mockApplicationConfig({})
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

  it('takes in drafts, archived and linked answers, unlike the sidebar list', async () => {
    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    renderFlyout()

    // Whether an answer already covers the topic is also answered by an unfinished or retired one —
    //   and by one that is already linked to the ticket, which the sidebar list leaves out.
    const calls = await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()
    expect(calls.at(-1)?.variables).toEqual({
      ticketId,
      includeDraftsAndArchived: true,
      includeLinkedAnswers: true,
    })
  })

  // That the answers of the earlier open are not rendered while this search runs comes from the
  //   `network-only` policy, which is covered in the composable's own spec — the intermediate frame
  //   is not observable from here.
  it('searches again on every open, ending up with the current answers', async () => {
    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    // Prime the Apollo cache the way an earlier open of the flyout would have.
    const primer = renderFlyout()
    await primer.findByText('Reset your password')
    primer.unmount()

    // Meanwhile the ticket moved on, so the answer of the first search no longer fits.
    mockSuggestedAnswers([relatedAnswer(2, 'Change your email address')])

    const wrapper = renderFlyout()

    expect(await wrapper.findByText('Change your email address')).toBeInTheDocument()
    expect(wrapper.queryByText('Reset your password')).not.toBeInTheDocument()
    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(2)
  })

  it('marks a draft answer as such', async () => {
    mockSuggestedAnswers([
      relatedAnswer(1, 'Reset your password', 0.88, EnumKnowledgeBaseVisibility.Draft),
    ])

    const wrapper = renderFlyout()

    expect(await wrapper.findByText('Reset your password')).toBeInTheDocument()
    expect(wrapper.getByIconName('kb-draft')).toBeInTheDocument()
  })

  it('drives the search itself, so a pending embedding resolves', async () => {
    mockSuggestedAnswers([], true)

    const wrapper = renderFlyout()

    expect(await wrapper.findByLabelText('Searching for related answers…')).toBeInTheDocument()

    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password')])

    // The widened search has its own result, so only the flyout’s own ping subscription can
    //   resolve it — the sidebar list cannot stand in for it.
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

  it('hides relevance score when the user does not have the right permissions', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])

    mockSuggestedAnswers([relatedAnswer(1, 'Reset your password', 0.88)])

    const wrapper = renderFlyout()

    expect(wrapper.queryByText('88%')).not.toBeInTheDocument()
  })
})
