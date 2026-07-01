// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import TicketAISuggestedKnowledgeBaseAnswers from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketAISuggestedKnowledgeBaseAnswers.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import {
  mockTicketAiRelatedKnowledgeBaseAnswersQuery,
  mockTicketAiRelatedKnowledgeBaseAnswersQueryError,
} from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.mocks.ts'
import { getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/ticketAIRelatedKnowledgeBaseAnswersUpdates.mocks.ts'

const ticketId = convertToGraphQLId('Ticket', 1)

const renderSuggestions = () =>
  renderComponent(TicketAISuggestedKnowledgeBaseAnswers, {
    provide: [
      [
        TICKET_KEY,
        {
          ticket: ref({ id: ticketId }),
          ticketId: ref(ticketId),
          ticketInternalId: ref(1),
        },
      ],
    ],
    router: true,
    store: true,
  })

const relatedAnswer = (id: number, title: string, score = 0.9) => ({
  score,
  translation: {
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
    title,
    answer: {
      id: convertToGraphQLId('KnowledgeBase::Answer', id),
      category: {
        knowledgeBase: { id: convertToGraphQLId('KnowledgeBase', 1) },
      },
    },
    kbLocale: { systemLocale: { locale: 'en-us' } },
  },
})

describe('TicketAISuggestedKnowledgeBaseAnswers', () => {
  it('renders the suggested answers returned by the query as links', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password'), relatedAnswer(2, 'Update billing')],
      },
    })

    const wrapper = renderSuggestions()

    expect(wrapper.getByText('Suggested by AI')).toBeInTheDocument()
    expect(await wrapper.findByText('Reset your password')).toBeInTheDocument()
    expect(wrapper.getByText('Update billing')).toBeInTheDocument()

    expect(wrapper.getByText('Reset your password').closest('a')).toHaveAttribute(
      'href',
      expect.stringContaining('#knowledge_base/1/locale/en-us/answer/1'),
    )
  })

  it('shows a waiting message while the ticket summary is still being generated', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: true,
        answers: null,
      },
    })

    const wrapper = renderSuggestions()

    expect(await wrapper.findByText('Searching for related answers…')).toBeInTheDocument()
  })

  it('ignores the initial subscription handshake so it keeps waiting for the real ping', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: true,
        answers: null,
      },
    })

    const wrapper = renderSuggestions()

    expect(await wrapper.findByText('Searching for related answers…')).toBeInTheDocument()

    // The content-free subscription handshake carries no ticketId, so it must not trigger a refetch.
    await getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler().trigger({
      ticketAIRelatedKnowledgeBaseAnswersUpdates: { ticketId: null },
    })

    expect(wrapper.getByText('Searching for related answers…')).toBeInTheDocument()
  })

  it('refetches when a real ping arrives and shows the now-available answers', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: true,
        answers: null,
      },
    })

    const wrapper = renderSuggestions()

    expect(await wrapper.findByText('Searching for related answers…')).toBeInTheDocument()

    // The embedding settled: the next query (refetch) resolves with answers.
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    await getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler().trigger({
      ticketAIRelatedKnowledgeBaseAnswersUpdates: { ticketId, error: null },
    })

    expect(await wrapper.findByText('Reset your password')).toBeInTheDocument()
  })

  it('shows the error state (and does not keep waiting) when the ping reports a failure', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: true,
        answers: null,
      },
    })

    const wrapper = renderSuggestions()

    expect(await wrapper.findByText('Searching for related answers…')).toBeInTheDocument()

    await getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler().trigger({
      ticketAIRelatedKnowledgeBaseAnswersUpdates: { ticketId, error: 'boom' },
    })

    expect(await wrapper.findByText(/The suggestions could not be generated/)).toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Retry' })).toBeInTheDocument()
  })

  it('shows the error with a retry button (and no feedback) when the search fails', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQueryError('boom', {
      type: GraphQLErrorTypes.UnknownError,
    })

    const wrapper = renderSuggestions()

    expect(await wrapper.findByText(/The suggestions could not be generated/)).toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Retry' })).toBeInTheDocument()
  })

  it('shows an empty message when there are no suggestions', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [],
      },
    })

    const wrapper = renderSuggestions()

    expect(await wrapper.findByText('No related knowledge base answers found.')).toBeInTheDocument()
  })
})
