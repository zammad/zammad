// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { computed, defineComponent, ref, toRef, type PropType } from 'vue'

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
  waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls,
} from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.mocks.ts'
import { getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/ticketAIRelatedKnowledgeBaseAnswersUpdates.mocks.ts'

import { useKnowledgeBaseAiSuggestedAnswers } from '../useKnowledgeBaseAiSuggestedAnswers.ts'

import type { WatchQueryFetchPolicy } from '@apollo/client'

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

interface TestProps {
  queryEnabled?: boolean
  subscriptionEnabled?: boolean
  fetchPolicy?: WatchQueryFetchPolicy
}

const TestComponent = defineComponent({
  props: {
    queryEnabled: { type: Boolean, default: true },
    subscriptionEnabled: { type: Boolean, default: true },
    fetchPolicy: { type: String as PropType<WatchQueryFetchPolicy>, default: 'cache-and-network' },
  },
  setup(props) {
    api = useKnowledgeBaseAiSuggestedAnswers(ref(ticketId), {
      queryEnabled: toRef(props, 'queryEnabled'),
      subscriptionEnabled: toRef(props, 'subscriptionEnabled'),
      fetchPolicy: toRef(props, 'fetchPolicy'),
    })
    return () => null
  },
})

const mountComposable = (props: TestProps = {}) =>
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

    // `updateArticle` must be pinned to `null`: the auto-mocker would otherwise generate a second
    // article, whose sender is drawn from the same small id pool and shares the cached object with
    // `addArticle` — randomly overwriting the sender name we ask for here.
    await getTicketArticleUpdatesSubscriptionHandler().trigger({
      ticketArticleUpdates: {
        addArticle: { sender: { name: EnumTicketArticleSenderName.Customer } },
        // Suppress the auto-generated update article and remove article id: the
        // update article's randomly generated sender can collide with the sender
        // of the added article in the object cache and overwrite the mocked
        // sender name above.
        updateArticle: null,
        removeArticleId: null,
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

  it('runs the query only once the query is enabled', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    const view = mountComposable({ queryEnabled: false })
    await flushPromises()

    // Nothing fetched while disabled.
    expect(api.answers.value).toEqual([])
    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(0)

    await view.rerender({ queryEnabled: true })
    await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()

    await waitFor(() => expect(api.answers.value).toHaveLength(1))
    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(1)
  })

  it('does not subscribe to updates when subscriptions are disabled', async () => {
    // The AI draft flyout relies on this while the sidebar list is visible: that list already holds
    //   the subscriptions and refetches into the same cache entry.
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable({ subscriptionEnabled: false })
    await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()

    expect(getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler()).toBeUndefined()
    expect(getTicketArticleUpdatesSubscriptionHandler()).toBeUndefined()
  })

  it('serves a second consumer from the cache with a cache-first policy', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    mountComposable()
    await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()

    mountComposable({ subscriptionEnabled: false, fetchPolicy: 'cache-first' })
    await flushPromises()

    // The second consumer sees the answers without hitting the network again.
    expect(api.answers.value).toHaveLength(1)
    expect(api.loading.value).toBe(false)
    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(1)
  })

  it('revalidates for a second consumer with a cache-and-network policy', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    mountComposable()
    await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()

    mountComposable({ subscriptionEnabled: false, fetchPolicy: 'cache-and-network' })

    await waitFor(() =>
      expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(2),
    )
  })
})
