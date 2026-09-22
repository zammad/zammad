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
  await waitFor(() => expect(handler.loadedArticlesCount.value).toBe(count))
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
    await waitFor(() => expect(handler.loadedArticlesCount.value).toBe(4))
    expect(handler.loadedArticleSelections.value).toMatchObject([
      { pageSize: 4, loadFirstArticles: true },
    ])
  })

  it('splits a retained window larger than the connection limit at actual cursors', async () => {
    const handler = await setup()
    const result = handler.articleResult.value!
    handler.articleResult.value = {
      ...result,
      articles: {
        ...result.articles,
        edges: edges(10, 2001).map((edge) =>
          Object.assign(edge, {
            __typename: 'TicketArticleEdge' as const,
            node: Object.assign({}, result.articles.edges[0].node, edge.node),
          }),
        ),
      },
    }
    expect(handler.loadedArticleSelections.value).toEqual([
      {
        ticketId,
        firstArticlesCount: 5,
        loadFirstArticles: true,
        pageSize: 2000,
        beforeCursor: 'cursor-2010',
      },
      {
        ticketId,
        firstArticlesCount: 5,
        loadFirstArticles: false,
        pageSize: 1,
        beforeCursor: undefined,
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
  })
})
