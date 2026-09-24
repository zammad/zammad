// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useArticleDataHandler } from '../useArticleDataHandler.ts'

const ticketId = convertToGraphQLId('Ticket', 1)
const edges = (start: number, count: number) =>
  Array.from({ length: count }, (_, index) => ({
    node: { id: convertToGraphQLId('Ticket::Article', start + index) },
    cursor: `cursor-${start + index}`,
  }))

const setup = async (count = 2) => {
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
        handler = useArticleDataHandler(ref(ticketId))
        return {}
      },
      template: '<div />',
    },
    { store: true },
  )
  await waitFor(() => expect(handler.articleResult.value?.articles.edges.length).toBe(count))
  return handler
}

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
    const retainedEdges = pageEdges(10, 2000)
    handler.articleResult.value = {
      ...result,
      articles: { ...result.articles, edges: retainedEdges },
    }
    const previous = handler.loadedArticleSelections.value[0]

    handler.articleResult.value = {
      ...result,
      articles: {
        ...result.articles,
        edges: [...pageEdges(9, 1), ...retainedEdges],
      },
    }

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
