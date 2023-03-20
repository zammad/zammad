// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { LastArrayElement } from 'type-fest'
import type { TicketArticlesQuery } from '@shared/graphql/types'
import { convertToGraphQLId } from '@shared/graphql/utils'
import { nullableMock } from '@tests/support/utils'
import { mockPermissions } from '@tests/support/mock-permissions'
import { visitView } from '@tests/support/components/visitView'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { defaultArticles, mockTicketDetailViewGql } from '../mocks/detail-view'

beforeEach(() => {
  mockPermissions(['ticket.agent'])
})

const now = new Date(2022, 1, 1, 0, 0, 0, 0)
vi.setSystemTime(now)

const ticketDate = new Date(2022, 0, 30, 0, 0, 0, 0)

const address = {
  __typename: 'AddressesField' as const,
  parsed: null,
  raw: '',
}

type ArticleNode = LastArrayElement<
  TicketArticlesQuery['articles']['edges']
>['node']

const articleContent = (
  id: number,
  mockedArticleData: Partial<ArticleNode>,
): ArticleNode => {
  return {
    __typename: 'TicketArticle',
    id: convertToGraphQLId('TicketArticle', id),
    internalId: id,
    createdAt: ticketDate.toISOString(),
    to: address,
    replyTo: address,
    cc: address,
    from: address,
    author: {
      __typename: 'User',
      id: 'fdsf214fse12d',
      firstname: 'John',
      lastname: 'Doe',
      fullname: 'John Doe',
      active: true,
      image: null,
      authorizations: [],
    },
    internal: false,
    bodyWithUrls: '<p>default body</p>',
    sender: {
      __typename: 'TicketArticleSender',
      name: 'Customer',
    },
    type: {
      __typename: 'TicketArticleType',
      name: 'article',
    },
    contentType: 'text/html',
    attachmentsWithoutInline: [],
    preferences: {},
    ...mockedArticleData,
  }
}

describe('ticket articles list with subscription', () => {
  it('shows a newly created article', async () => {
    const defaultArticlesQuery = defaultArticles()
    const newArticlesQuery: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls:
                '<p>Existing article> only agents can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 4,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(4, {
              bodyWithUrls: '<p>New article> only agents can see this haha</p>',
              createdAt: new Date(2022, 0, 31, 0, 0, 0, 0).toISOString(),
            }),
            cursor: 'MI',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const { waitUntilTicketLoaded, mockTicketArticleSubscription } =
      mockTicketDetailViewGql({
        articles: [defaultArticlesQuery, newArticlesQuery],
      })

    const view = await visitView('/tickets/1')
    await waitUntilTicketLoaded()

    let comments = view.getAllByRole('comment')
    expect(comments.length).toBe(3)

    comments.forEach((_value, i) => {
      expect(comments[i]).not.toHaveTextContent('New article')
    })

    await mockTicketArticleSubscription.next(
      nullableMock({
        data: {
          ticketArticleUpdates: {
            addArticle: {
              __typename: 'TicketArticle',
              id: 'gid://zammad/Article/4',
              createdAt: new Date(2022, 0, 31, 0, 0, 0, 0).toISOString(),
            },
          },
        },
      }),
    )

    comments = view.getAllByRole('comment')
    expect(comments.length).toBe(4)
    expect(comments[3]).toHaveTextContent('New article')
  })

  it('updates the list after a former visible article is deleted', async () => {
    const { waitUntilTicketLoaded, mockTicketArticleSubscription } =
      mockTicketDetailViewGql()

    const view = await visitView('/tickets/1')
    await waitUntilTicketLoaded()

    let comments = view.getAllByRole('comment')
    expect(comments.length).toBe(3)

    await mockTicketArticleSubscription.next(
      nullableMock({
        data: {
          ticketArticleUpdates: {
            removeArticleId: 'gid://zammad/Article/3',
          },
        },
      }),
    )

    comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
  })

  it('updates the list after a non-visible article is deleted', async () => {
    mockApplicationConfig({
      ticket_articles_min: 1,
    })

    const newArticlesQuery: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls:
                '<p>Existing article> only agents can see this haha</p>',
            }),
            cursor: 'MI',
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 3,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(2, {
              bodyWithUrls: '<p>New article> only agents can see this haha</p>',
            }),
            cursor: 'MI',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const newArticlesQueryAfterDelete: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls:
                '<p>Existing article> only agents can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 2,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(2, {
              bodyWithUrls: '<p>New article> only agents can see this haha</p>',
            }),
            cursor: 'MI',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const { waitUntilTicketLoaded, mockTicketArticleSubscription } =
      mockTicketDetailViewGql({
        articles: [newArticlesQuery, newArticlesQueryAfterDelete],
      })

    const view = await visitView('/tickets/1')
    await waitUntilTicketLoaded()

    let comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
    expect(view.getByText('load 1 more')).toBeInTheDocument()

    await mockTicketArticleSubscription.next(
      nullableMock({
        data: {
          ticketArticleUpdates: {
            removeArticleId: 'gid://zammad/Article/3',
          },
        },
      }),
    )

    comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()
  })

  it('updates the list after a former visible article at the end of the list is switched to public', async () => {
    const newArticlesQuery: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 2,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(2, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
            cursor: 'MI',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const newArticlesQueryAfterUpdate: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 3,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls:
                '<p>Existing article switched to public> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MH',
        },
      },
    })

    const { waitUntilTicketLoaded, mockTicketArticleSubscription } =
      mockTicketDetailViewGql({
        articles: [newArticlesQuery, newArticlesQueryAfterUpdate],
      })

    const view = await visitView('/tickets/1')
    await waitUntilTicketLoaded()

    let comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
    expect(
      view.queryByText('Existing article switched to public'),
    ).not.toBeInTheDocument()
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()

    await mockTicketArticleSubscription.next(
      nullableMock({
        data: {
          ticketArticleUpdates: {
            addArticle: {
              __typename: 'TicketArticle',
              id: 'gid://zammad/Article/3',
              createdAt: new Date(2022, 0, 31, 10, 0, 0, 0).toISOString(),
            },
          },
        },
      }),
    )

    comments = view.getAllByRole('comment')
    expect(comments.length).toBe(3)
    expect(comments[2]).toHaveTextContent('Existing article switched to public')
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()
  })

  it('updates the list after a former visible article at the end of the list is switched to internal', async () => {
    const newArticlesQuery: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 3,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(2, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
            cursor: 'MI',
          },
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls:
                '<p>Existing article switched to internal> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const newArticlesQueryAfterUpdate: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 2,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(2, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
            cursor: 'MI',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const { waitUntilTicketLoaded, mockTicketArticleSubscription } =
      mockTicketDetailViewGql({
        articles: [newArticlesQuery, newArticlesQueryAfterUpdate],
      })

    const view = await visitView('/tickets/1')
    await waitUntilTicketLoaded()

    let comments = view.getAllByRole('comment')
    expect(comments.length).toBe(3)
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()
    expect(comments[2]).toHaveTextContent(
      'Existing article switched to internal',
    )

    await mockTicketArticleSubscription.next(
      nullableMock({
        data: {
          ticketArticleUpdates: {
            removeArticleId: 'gid://zammad/Article/3',
          },
        },
      }),
    )

    comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()
    expect(
      view.queryByText('Existing article switched to internal'),
    ).not.toBeInTheDocument()
  })

  it('updates the list after a former visible article in between is switched to public', async () => {
    const newArticlesQuery: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 2,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls:
                '<p>Existing article switched to public> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MH',
        },
      },
    })

    const newArticlesQueryAfterUpdate: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 3,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(2, {
              bodyWithUrls:
                '<p>Internal article switched to public> all can see this haha</p>',
            }),
            cursor: 'MI',
          },
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls:
                '<p>Existing article switched to public> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const { waitUntilTicketLoaded, mockTicketArticleSubscription } =
      mockTicketDetailViewGql({
        articles: [newArticlesQuery, newArticlesQueryAfterUpdate],
      })

    const view = await visitView('/tickets/1')
    await waitUntilTicketLoaded()

    let comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
    expect(
      view.queryByText('Internal article switched to public'),
    ).not.toBeInTheDocument()
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()

    await mockTicketArticleSubscription.next(
      nullableMock({
        data: {
          ticketArticleUpdates: {
            addArticle: {
              __typename: 'TicketArticle',
              id: 'gid://zammad/Article/2',
              createdAt: new Date(2022, 0, 27, 10, 0, 0, 0).toISOString(),
            },
          },
        },
      }),
    )

    comments = view.getAllByRole('comment')
    expect(comments.length).toBe(3)
    expect(comments[2]).toHaveTextContent('Existing article switched to public')
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()
  })

  it('updates the list after a former visible article in between is switched to internal', async () => {
    const newArticlesQuery: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 3,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(2, {
              bodyWithUrls:
                '<p>Existing article switched to internal> all can see this haha</p>',
            }),
            cursor: 'MI',
          },
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const newArticlesQueryAfterUpdate: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 2,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const { waitUntilTicketLoaded, mockTicketArticleSubscription } =
      mockTicketDetailViewGql({
        articles: [newArticlesQuery, newArticlesQueryAfterUpdate],
      })

    const view = await visitView('/tickets/1')
    await waitUntilTicketLoaded()

    let comments = view.getAllByRole('comment')
    expect(comments.length).toBe(3)
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()
    expect(comments[1]).toHaveTextContent(
      'Existing article switched to internal',
    )

    await mockTicketArticleSubscription.next(
      nullableMock({
        data: {
          ticketArticleUpdates: {
            removeArticleId: 'gid://zammad/Article/2',
          },
        },
      }),
    )

    comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()
    expect(
      view.queryByText('Existing article switched to internal'),
    ).not.toBeInTheDocument()
  })

  it('updates the list after a non-visible article in between is switched to public', async () => {
    mockApplicationConfig({
      ticket_articles_min: 1,
    })

    const newArticlesQuery: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls:
                '<p>Existing article> only agents can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 3,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MH',
        },
      },
    })

    const newArticlesQueryAfterUpdate: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls:
                '<p>Existing article> only agents can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 3,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(2, {
              bodyWithUrls:
                '<p>New article switched to public> only agents can see this haha</p>',
            }),
            cursor: 'MI',
          },
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const { waitUntilTicketLoaded, mockTicketArticleSubscription } =
      mockTicketDetailViewGql({
        articles: [newArticlesQuery, newArticlesQueryAfterUpdate],
      })

    const view = await visitView('/tickets/1')
    await waitUntilTicketLoaded()

    let comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
    expect(
      view.queryByText('New article switched to public'),
    ).not.toBeInTheDocument()
    expect(view.getByText('load 1 more')).toBeInTheDocument()

    await mockTicketArticleSubscription.next(
      nullableMock({
        data: {
          ticketArticleUpdates: {
            addArticle: {
              __typename: 'TicketArticle',
              id: 'gid://zammad/Article/2',
              createdAt: new Date(2022, 0, 30, 10, 0, 0, 0).toISOString(),
            },
          },
        },
      }),
    )

    comments = view.getAllByRole('comment')
    expect(comments.length).toBe(3)
    expect(comments[1]).toHaveTextContent('New article switched to public')
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()
  })

  it('updates the list after a non-visible article in between is switched to internal', async () => {
    mockApplicationConfig({
      ticket_articles_min: 1,
    })

    const newArticlesQuery: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls:
                '<p>Existing article> only agents can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 3,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MH',
        },
      },
    })

    const newArticlesQueryAfterUpdate: TicketArticlesQuery = nullableMock({
      description: {
        __typename: 'TicketArticleConnection',
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(1, {
              bodyWithUrls:
                '<p>Existing article> only agents can see this haha</p>',
            }),
          },
        ],
      },
      articles: {
        __typename: 'TicketArticleConnection',
        totalCount: 3,
        edges: [
          {
            __typename: 'TicketArticleEdge',
            node: articleContent(3, {
              bodyWithUrls: '<p>Existing article> all can see this haha</p>',
            }),
            cursor: 'MH',
          },
        ],
        pageInfo: {
          __typename: 'PageInfo',
          hasPreviousPage: false,
          startCursor: 'MI',
        },
      },
    })

    const { waitUntilTicketLoaded, mockTicketArticleSubscription } =
      mockTicketDetailViewGql({
        articles: [newArticlesQuery, newArticlesQueryAfterUpdate],
      })

    const view = await visitView('/tickets/1')
    await waitUntilTicketLoaded()

    let comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
    expect(
      view.queryByText('New article switched to internal'),
    ).not.toBeInTheDocument()
    expect(view.getByText('load 1 more')).toBeInTheDocument()

    await mockTicketArticleSubscription.next(
      nullableMock({
        data: {
          ticketArticleUpdates: {
            removeArticleId: 'gid://zammad/Article/2',
          },
        },
      }),
    )

    comments = view.getAllByRole('comment')
    expect(comments.length).toBe(2)
    expect(
      view.queryByText('New article switched to internal'),
    ).not.toBeInTheDocument()
    expect(view.queryByText('load 1 more')).not.toBeInTheDocument()
  })
})
