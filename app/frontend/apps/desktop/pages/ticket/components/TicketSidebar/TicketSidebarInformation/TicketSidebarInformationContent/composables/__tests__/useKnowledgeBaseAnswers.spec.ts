// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { computed, defineComponent, ref, toRef } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { getTicketArticleUpdatesSubscriptionHandler } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.mocks.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/schema-types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { TicketAiRelatedKnowledgeBaseAnswersDocument } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.api.ts'
import {
  mockTicketAiRelatedKnowledgeBaseAnswersQuery,
  mockTicketAiRelatedKnowledgeBaseAnswersQueryError,
} from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.mocks.ts'
import { getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/ticketAIRelatedKnowledgeBaseAnswersUpdates.mocks.ts'

import { useKnowledgeBaseAiSuggestedAnswers } from '../useKnowledgeBaseAnswers.ts'

const ticketId = convertToGraphQLId('Ticket', 1)

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

let api: ReturnType<typeof useKnowledgeBaseAiSuggestedAnswers>

const TestComponent = defineComponent({
  props: {
    enabled: { type: Boolean, default: true },
  },
  setup(props) {
    api = useKnowledgeBaseAiSuggestedAnswers(ref(ticketId), {
      enabled: toRef(props, 'enabled'),
    })
    return () => null
  },
})

const mountComposable = (props: { enabled?: boolean } = {}) =>
  renderComponent(TestComponent, {
    props,
    provide: [
      [
        TICKET_KEY,
        {
          ticket: computed(() => ({ id: ticketId })),
          ticketId: computed(() => ticketId),
          ticketInternalId: computed(() => 1),
        },
      ],
    ],
  })

describe('useKnowledgeBaseAiSuggestedAnswers', () => {
  it('exposes the answers from the query, with the score rounded to a percentage', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password', 0.876)],
      },
    })

    mountComposable()
    await flushPromises()

    expect(api.answers.value).toEqual([
      expect.objectContaining({
        score: 88,
        translation: expect.objectContaining({ id: expect.any(String) }),
      }),
    ])
    expect(api.loading.value).toBe(false)
    expect(api.pending.value).toBe(false)
  })

  it('is pending while the embedding is still being generated', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: true, answers: null },
    })

    mountComposable()
    await flushPromises()

    expect(api.pending.value).toBe(true)
  })

  it('refetches when a ping reports the embedding is ready', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: true, answers: null },
    })

    mountComposable()
    await flushPromises()

    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    await getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler().trigger({
      ticketAIRelatedKnowledgeBaseAnswersUpdates: { ticketId, error: null },
    })

    await waitFor(() => expect(api.answers.value).toHaveLength(1))
  })

  it('refetches when a new (non-system) article is added', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable()
    await flushPromises()

    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    await getTicketArticleUpdatesSubscriptionHandler().trigger({
      ticketArticleUpdates: {
        addArticle: { sender: { name: EnumTicketArticleSenderName.Customer } },
      },
    })

    await waitFor(() => expect(api.answers.value).toHaveLength(1))
  })

  it('shows the error the embed job reports via the ping subscription', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: true, answers: null },
    })

    mountComposable()
    await flushPromises()

    await getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler().trigger({
      ticketAIRelatedKnowledgeBaseAnswersUpdates: { ticketId, error: 'boom' },
    })

    await waitFor(() => expect(api.hasError.value).toBe(true))
    expect(api.errorDetail.value).toBe('boom')
  })

  it('shows the error when the search query itself fails, and clears it on retry', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQueryError('boom', {
      type: GraphQLErrorTypes.UnknownError,
    })

    mountComposable()
    await flushPromises()

    expect(api.hasError.value).toBe(true)

    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    api.retrySearch()

    await waitFor(() => expect(api.hasError.value).toBe(false))
  })

  it('does not run the query or subscriptions when disabled', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable({ enabled: false })
    await flushPromises()

    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(0)
  })
})
