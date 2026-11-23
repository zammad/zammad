// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { ref } from 'vue'

import { getGraphQLSubscriptionHandler } from '#tests/graphql/builders/mocks.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import {
  mockTicketArticlesQuery,
  waitForTicketArticlesQueryCalls,
} from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { TicketArticleUpdatesDocument } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.api.ts'
import { getTicketArticleUpdatesSubscriptionHandler } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.mocks.ts'
import type { TicketArticleUpdatesSubscription } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useArticleDataHandler } from '../useArticleDataHandler.ts'

const ticketId = convertToGraphQLId('Ticket', 1)
const edges = (start: number, count: number) =>
  Array.from({ length: count }, (_, index) => ({
    node: { id: convertToGraphQLId('Ticket::Article', start + index) },
    cursor: `cursor-${start + index}`,
  }))

const setup = async (
  count = 2,
  currentTicketId = ref(ticketId),
  options: Parameters<typeof useArticleDataHandler>[1] = { pageSize: 20 },
) => {
  mockTicketArticlesQuery({
    firstArticles: { edges: edges(1, 1) },
    articles: {
      edges: edges(10, count),
      totalCount: 3000,
      pageInfo: {
        startCursor: 'cursor-10',
        endCursor: `cursor-${9 + count}`,
        hasPreviousPage: true,
      },
    },
  })
  let handler!: ReturnType<typeof useArticleDataHandler>
  renderComponent(
    {
      setup() {
        handler = useArticleDataHandler(currentTicketId, options)
        return {}
      },
      template: '<div />',
    },
    { store: true },
  )
  await waitFor(() => expect(handler.articleResult.value?.articles.edges.length).toBe(count))
  return handler
}

describe('articles query', () => {
  it('reloads the articles when the subscription asks for it', async () => {
    await setup()
    const callsBefore = (await waitForTicketArticlesQueryCalls()).length

    await getTicketArticleUpdatesSubscriptionHandler().trigger({
      ticketArticleUpdates: {
        addArticle: null,
        updateArticle: null,
        removeArticleId: null,
        refetchArticles: true,
      },
    })

    const calls = await waitForTicketArticlesQueryCalls()

    await waitFor(() => expect(calls).toHaveLength(callsBefore + 1))
    expect(calls.at(-1)?.variables).toMatchObject({ ticketId })
  })

  const newArticleId = convertToGraphQLId('Ticket::Article', 100)
  const loadedArticleIds = [9, 10, 11].map((id) => convertToGraphQLId('Ticket::Article', id))
  const articleIds = (handler: ReturnType<typeof useArticleDataHandler>) =>
    handler.articleResult.value?.articles.edges.map((edge) => edge.node.id)

  const loadOlderArticles = async (handler: ReturnType<typeof useArticleDataHandler>) => {
    mockTicketArticlesQuery({
      articles: {
        edges: edges(8, 2),
        totalCount: 3000,
        pageInfo: { startCursor: 'cursor-8', endCursor: 'cursor-9', hasPreviousPage: true },
      },
    })
    await handler.loadPreviousArticles(2)
    await waitFor(() => expect(handler.articleResult.value?.articles.edges.length).toBe(4))

    // The new article pushes the oldest loaded one out of the newest four.
    mockTicketArticlesQuery({
      firstArticles: { edges: edges(1, 1) },
      articles: {
        edges: [...edges(9, 3), { node: { id: newArticleId }, cursor: 'cursor-new' }],
        totalCount: 3001,
        pageInfo: { startCursor: 'cursor-9', endCursor: 'cursor-new', hasPreviousPage: true },
      },
    })
  }

  const triggerArticleUpdate = (updates: object, variables?: Record<string, unknown>) =>
    getGraphQLSubscriptionHandler<TicketArticleUpdatesSubscription>(
      TicketArticleUpdatesDocument,
      variables,
    ).trigger({
      ticketArticleUpdates: {
        addArticle: null,
        updateArticle: null,
        removeArticleId: null,
        refetchArticles: null,
        ...updates,
      },
    })

  it('keeps the loaded number of articles when articles were merged into the ticket', async () => {
    const handler = await setup(2, ref(ticketId), { pageSize: 2 })
    await loadOlderArticles(handler)

    await triggerArticleUpdate({ refetchArticles: true })

    await waitFor(() => expect(articleIds(handler)).toEqual([...loadedArticleIds, newArticleId]))
    const calls = await waitForTicketArticlesQueryCalls()
    expect(calls.at(-1)?.variables).toMatchObject({ pageSize: 4 })
  })

  it('lets a new article reload the loaded number of articles', async () => {
    const handler = await setup(2, ref(ticketId), {
      pageSize: 2,
      onAddArticleCallback: ({ refetchLoadedArticles }) => refetchLoadedArticles(),
    })
    await loadOlderArticles(handler)

    await triggerArticleUpdate({
      addArticle: { id: newArticleId, createdAt: new Date().toISOString() },
    })

    await waitFor(() => expect(articleIds(handler)).toEqual([...loadedArticleIds, newArticleId]))
    const calls = await waitForTicketArticlesQueryCalls()
    expect(calls.at(-1)?.variables).toMatchObject({ pageSize: 4 })
  })

  it('keeps all articles when merged ones arrive after a partly filled older page', async () => {
    const page = (start: number, count: number, totalCount: number) => ({
      firstArticles: { edges: edges(1, 1) },
      articles: {
        edges: edges(start, count),
        totalCount,
        pageInfo: {
          startCursor: `cursor-${start}`,
          endCursor: `cursor-${start + count - 1}`,
          hasPreviousPage: start > 1,
        },
      },
    })
    mockTicketArticlesQuery(page(13, 20, 32))
    let handler!: ReturnType<typeof useArticleDataHandler>
    renderComponent(
      {
        setup() {
          handler = useArticleDataHandler(ref(ticketId), { pageSize: 20 })
          return {}
        },
        template: '<div />',
      },
      { store: true },
    )
    await waitFor(() => expect(handler.articleResult.value?.articles.edges.length).toBe(20))

    mockTicketArticlesQuery(page(1, 12, 32))
    await handler.loadPreviousArticles(100)
    await waitFor(() => expect(handler.articleResult.value?.articles.edges.length).toBe(32))

    mockTicketArticlesQuery(page(1, 40, 40))
    await triggerArticleUpdate({ refetchArticles: true })

    await waitFor(() =>
      expect(articleIds(handler)).toEqual(edges(1, 40).map((edge) => edge.node.id)),
    )
    const calls = await waitForTicketArticlesQueryCalls()
    expect(calls.at(-1)?.variables).toMatchObject({ pageSize: 120 })
  })

  it('reloads the first page when no older articles were requested', async () => {
    await setup()

    await triggerArticleUpdate({ refetchArticles: true })

    const calls = await waitForTicketArticlesQueryCalls()
    await waitFor(() => expect(calls.at(-1)?.variables).toMatchObject({ pageSize: 20 }))
    expect(calls).toHaveLength(2)
  })

  it('ignores older articles that arrive after the ticket changed', async () => {
    const currentTicketId = ref(ticketId)
    const handler = await setup(2, currentTicketId)

    let deliverOlderArticles!: () => void
    mockTicketArticlesQuery(
      () =>
        new Promise((resolve) => {
          deliverOlderArticles = () => resolve({ articles: { edges: edges(8, 2) } })
        }),
    )
    const loading = handler.loadPreviousArticles(100)

    const otherTicketId = convertToGraphQLId('Ticket', 2)
    mockTicketArticlesQuery({ articles: { edges: edges(20, 2), totalCount: 2 } })
    currentTicketId.value = otherTicketId
    const calls = await waitForTicketArticlesQueryCalls()
    await waitFor(() => expect(calls.at(-1)?.variables).toMatchObject({ ticketId: otherTicketId }))

    deliverOlderArticles()
    await loading

    await triggerArticleUpdate({ refetchArticles: true }, { ticketId: otherTicketId })

    await waitFor(() =>
      expect(calls.at(-1)?.variables).toMatchObject({ ticketId: otherTicketId, pageSize: 20 }),
    )
  })

  it('starts another ticket at its own page size', async () => {
    const currentTicketId = ref(ticketId)
    const handler = await setup(2, currentTicketId)
    await handler.loadPreviousArticles(100)

    const otherTicketId = convertToGraphQLId('Ticket', 2)
    currentTicketId.value = otherTicketId
    const calls = await waitForTicketArticlesQueryCalls()
    await waitFor(() => expect(calls.at(-1)?.variables).toMatchObject({ ticketId: otherTicketId }))

    await triggerArticleUpdate({ refetchArticles: true }, { ticketId: otherTicketId })

    await waitFor(() =>
      expect(calls.at(-1)?.variables).toMatchObject({ ticketId: otherTicketId, pageSize: 20 }),
    )
    expect(calls.at(-1)?.variables).not.toHaveProperty('beforeCursor', 'cursor-10')
  })
})

describe('article selections', () => {
  it('describes the leading page and loaded trailing window', async () => {
    const handler = await setup()
    expect(handler.loadedArticleSelections.value).toEqual([
      {
        ticketId,
        firstArticlesCount: 5,
        loadFirstArticles: true,
        pageSize: 2,
        beforeCursor: undefined,
      },
    ])
  })

  it('includes pages retained by the relay cache after fetching older articles', async () => {
    const handler = await setup()
    const previousEdges = handler.articleResult.value!.articles.edges
    const previousLeading = handler.articleResult.value!.firstArticles!.edges[0].node
    mockTicketArticlesQuery({
      articles: {
        edges: edges(8, 2),
        totalCount: 3000,
        pageInfo: { startCursor: 'cursor-8', endCursor: 'cursor-9', hasPreviousPage: true },
      },
    })
    await handler.articlesQuery.fetchMore({
      variables: {
        pageSize: 2,
        beforeCursor: 'cursor-10',
        loadFirstArticles: false,
      },
    })
    await waitFor(() => expect(handler.articleResult.value?.articles.edges.length).toBe(4))
    expect(handler.articleResult.value!.articles.edges[2]).toBe(previousEdges[0])
    expect(handler.articleResult.value!.firstArticles!.edges[0].node).toBe(previousLeading)
    expect(handler.loadedArticleSelections.value).toMatchObject([
      { pageSize: 4, loadFirstArticles: true },
    ])
  })

  it('preserves a full page when older articles extend the retained window', async () => {
    const handler = await setup()
    const result = handler.articleResult.value!
    const pageEdges = (start: number, count: number) =>
      edges(start, count).map((edge) =>
        Object.assign(edge, {
          __typename: 'TicketArticleEdge' as const,
          node: Object.assign({}, result.articles.edges[0].node, edge.node),
        }),
      )

    // The result ref is read-only, so the retained window is widened through the query cache.
    handler.articlesQuery.operationResult.updateQuery(() => ({
      ...result,
      articles: { ...result.articles, edges: pageEdges(10, 2000) },
    }))
    await waitFor(() => expect(handler.articleResult.value?.articles.edges.length).toBe(2000))
    const previous = handler.loadedArticleSelections.value[0]

    // Older articles arrive the way they do in the app, so the relay merge keeps the edge identities.
    mockTicketArticlesQuery({
      articles: {
        edges: edges(9, 1),
        totalCount: 3000,
        pageInfo: { startCursor: 'cursor-9', endCursor: 'cursor-9', hasPreviousPage: true },
      },
    })
    await handler.articlesQuery.fetchMore({
      variables: {
        pageSize: 1,
        beforeCursor: 'cursor-10',
        loadFirstArticles: false,
      },
    })
    await waitFor(() => expect(handler.articleResult.value?.articles.edges.length).toBe(2001))

    expect(handler.loadedArticleSelections.value).toHaveLength(2)
    expect(handler.loadedArticleSelections.value[0]).toBe(previous)
    expect(handler.loadedArticleSelections.value).toMatchObject([
      {
        loadFirstArticles: true,
        pageSize: 2000,
        beforeCursor: undefined,
      },
      {
        loadFirstArticles: false,
        pageSize: 1,
        beforeCursor: 'cursor-10',
      },
    ])
  })

  it('refreshes the selection when different articles replace an equally sized page', async () => {
    const handler = await setup()
    const previous = handler.loadedArticleSelections.value
    mockTicketArticlesQuery({
      firstArticles: { edges: edges(1, 1) },
      articles: {
        edges: edges(11, 2),
        totalCount: 3000,
        pageInfo: { startCursor: 'cursor-11', endCursor: 'cursor-12', hasPreviousPage: true },
      },
    })
    await handler.articlesQuery.refetch()
    await waitFor(() => expect(handler.loadedArticleSelections.value).not.toBe(previous))
    expect(handler.loadedArticleSelections.value).toEqual(previous)
    expect(handler.loadedArticleSelections.value[0]).not.toBe(previous[0])
  })
})
