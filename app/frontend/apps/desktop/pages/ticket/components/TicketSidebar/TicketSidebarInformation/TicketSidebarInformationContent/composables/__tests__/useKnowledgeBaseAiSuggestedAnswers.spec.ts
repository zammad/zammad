// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { computed, defineComponent, nextTick, ref, toRef, type PropType } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { getTicketArticleUpdatesSubscriptionHandler } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.mocks.ts'
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

// The article count the caller hands in, from the ticket it holds. Raising it is what a new article
//   looks like from here; a System one leaves it alone, as the server does not count those.
const ticketArticleCount = ref(1)

const raiseArticleCount = () => {
  ticketArticleCount.value += 1
}

let api: ReturnType<typeof useKnowledgeBaseAiSuggestedAnswers>

interface TestProps {
  queryEnabled?: boolean
  subscriptionEnabled?: boolean
  fetchPolicy?: WatchQueryFetchPolicy
  includeDraftsAndArchived?: boolean
  includeLinkedAnswers?: boolean
}

const TestComponent = defineComponent({
  props: {
    queryEnabled: { type: Boolean, default: true },
    subscriptionEnabled: { type: Boolean, default: true },
    fetchPolicy: { type: String as PropType<WatchQueryFetchPolicy>, default: 'cache-and-network' },
    includeDraftsAndArchived: { type: Boolean, default: false },
    includeLinkedAnswers: { type: Boolean, default: false },
  },
  setup(props) {
    api = useKnowledgeBaseAiSuggestedAnswers(ref(ticketId), {
      queryEnabled: toRef(props, 'queryEnabled'),
      subscriptionEnabled: toRef(props, 'subscriptionEnabled'),
      fetchPolicy: toRef(props, 'fetchPolicy'),
      includeDraftsAndArchived: props.includeDraftsAndArchived,
      includeLinkedAnswers: props.includeLinkedAnswers,
      articleCount: () => ticketArticleCount.value,
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
  beforeEach(() => {
    ticketArticleCount.value = 1
  })

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

  it('searches only the internally visible answers that are not linked yet, by default', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable()

    const calls = await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()
    expect(calls.at(-1)?.variables).toEqual({
      ticketId,
      includeDraftsAndArchived: false,
      includeLinkedAnswers: false,
    })
  })

  it('searches drafts and archived answers when asked to', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable({ includeDraftsAndArchived: true })

    const calls = await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()
    expect(calls.at(-1)?.variables).toEqual({
      ticketId,
      includeDraftsAndArchived: true,
      includeLinkedAnswers: false,
    })
  })

  it('searches the answers already linked to the ticket when asked to', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable({ includeLinkedAnswers: true })

    const calls = await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()
    expect(calls.at(-1)?.variables).toEqual({
      ticketId,
      includeDraftsAndArchived: false,
      includeLinkedAnswers: true,
    })
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

  it('stays pending while a refresh it triggered itself is in flight', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    mountComposable()
    await waitFor(() => expect(api.answers.value).toHaveLength(1))
    expect(api.pending.value).toBe(false)

    api.retrySearch()

    // The answers on screen are the ones from before the refresh. Neither flag of the query says so:
    //   the previous result is still the current one (not pending), and `loading` ignores a request
    //   that has a result behind it.
    expect(api.loading.value).toBe(false)
    expect(api.pending.value).toBe(true)

    await waitFor(() => expect(api.pending.value).toBe(false))
    expect(api.answers.value).toHaveLength(1)
  })

  it('keeps the answers on screen while the refresh after an unlink runs', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    mountComposable()
    await waitFor(() => expect(api.answers.value).toHaveLength(1))

    api.refreshKeepingAnswers()

    // Unlike a refresh the ticket forced, this one does not send the list into its waiting state:
    //   the answers are still the right ones, only an unlinked one may join them.
    expect(api.pending.value).toBe(false)
    expect(api.answers.value).toHaveLength(1)

    await flushPromises()
    expect(api.pending.value).toBe(false)
  })

  it('keeps the answers on screen when a second unlink refresh follows the first', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    mountComposable()
    await waitFor(() => expect(api.answers.value).toHaveLength(1))

    api.refreshKeepingAnswers()
    api.refreshKeepingAnswers()

    expect(api.pending.value).toBe(false)
    expect(api.answers.value).toHaveLength(1)
  })

  it('keeps waiting when an unlink refresh starts while a refresh for new content runs', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    mountComposable()
    await waitFor(() => expect(api.answers.value).toHaveLength(1))

    raiseArticleCount()
    await nextTick()
    expect(api.pending.value).toBe(true)

    // The answers on screen predate the new article, so the unlink refresh must not present them as
    //   the current ones — the refresh that is already waiting for the new content wins.
    api.refreshKeepingAnswers()

    expect(api.pending.value).toBe(true)
  })

  it('refetches when the ticket gained an article', async () => {
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

    // What the ticket reports when an article arrives. System articles are counted out server-side,
    //   so there is no sender to check here.
    raiseArticleCount()

    await waitFor(() => expect(api.answers.value).toHaveLength(1))
  })

  it('does not search again while the article count is unchanged', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable()
    const calls = await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()
    const initialCallCount = calls.length

    await flushPromises()

    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(
      initialCallCount,
    )
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
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable({ subscriptionEnabled: false })
    const calls = await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()
    const initialCallCount = calls.length

    expect(getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler()).toBeUndefined()

    raiseArticleCount()
    await flushPromises()

    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(
      initialCallCount,
    )
  })

  it('never opens an article subscription of its own', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable()
    await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()

    // The ticket detail view already holds one; new articles reach us through the cached ticket.
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

  it('ignores the cache for a consumer with a network-only policy', async () => {
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [relatedAnswer(1, 'Reset your password')],
      },
    })

    mountComposable()
    await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()

    mountComposable({ subscriptionEnabled: false, fetchPolicy: 'network-only' })

    // The cache is served before any network answer, so this is the moment a `cache-and-network`
    //   consumer would already expose the previous answers. This one waits for its own result.
    await nextTick()
    expect(api.answers.value).toEqual([])
    expect(api.loading.value).toBe(true)

    await waitFor(() => expect(api.loading.value).toBe(false))
    expect(api.answers.value).toHaveLength(1)
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
