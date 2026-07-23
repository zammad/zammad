// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

// The infinite scroll is driven by @vueuse/core; capture its callback so the
//   test can simulate the user reaching the end of the list.
let triggerLoadMore: (() => Promise<void>) | undefined

vi.mock('@vueuse/core', async (importOriginal) => {
  const modules = await importOriginal<typeof import('@vueuse/core')>()

  return {
    ...modules,
    useInfiniteScroll: (_element: unknown, callback: () => Promise<void>) => {
      triggerLoadMore = callback
      return { reset: vi.fn(), isLoading: ref(false) }
    },
  }
})

const answer = (id: number, title: string) => ({
  node: {
    id: convertToGraphQLId('KnowledgeBase::Answer', id),
    title,
    visibility: EnumKnowledgeBaseVisibility.Published,
    position: id,
  },
})

describe('knowledge base answers infinite scroll', () => {
  beforeEach(() => {
    triggerLoadMore = undefined

    mockApplicationConfig({ kb_active_publicly: true })

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        title: 'My Knowledge Base',
        iconset: 'default',
        isPubliclyAvailable: true,
        isVisiblePublicly: true,
        kbLocales: [
          {
            id: convertToGraphQLId('KnowledgeBase::Locale', 1),
            primary: true,
            systemLocale: { id: '1', locale: 'en-us', name: 'English (United States)' },
          },
        ],
        // Pin the resolved locale to the same system locale as the primary
        //   kbLocale. Both resolve to Locale id 1, so leaving currentLocale
        //   unmocked lets the auto-mocker generate a random `locale` for that
        //   shared id, which then fails the section's known-locale gate.
        currentLocale: {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          systemLocale: { id: '1', locale: 'en-us' },
        },
      },
    })

    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: {
        category: { id: CATEGORY_ID, breadcrumb: [{ id: CATEGORY_ID, title: 'Category' }] },
        subcategories: [],
      },
    })

    // First page: two answers, more to come. Second page (requested with a
    //   cursor): the remaining two answers, no further pages.
    mockKnowledgeBaseAnswersQuery(({ cursor }) =>
      cursor
        ? {
            knowledgeBaseAnswers: {
              totalCount: 4,
              edges: [answer(3, 'Answer Three'), answer(4, 'Answer Four')],
              pageInfo: { endCursor: null, hasNextPage: false },
            },
          }
        : {
            knowledgeBaseAnswers: {
              totalCount: 4,
              edges: [answer(1, 'Answer One'), answer(2, 'Answer Two')],
              pageInfo: { endCursor: 'CURSOR', hasNextPage: true },
            },
          },
    )
  })

  it('appends the next page of answers when the list end is reached', async () => {
    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(CATEGORY_ID)}`,
    )

    expect(await view.findByText('Answer One')).toBeInTheDocument()
    expect(view.queryByText('Answer Three')).not.toBeInTheDocument()

    await triggerLoadMore?.()

    // The second page is appended, not replacing the first — relies on the
    //   relay-style pagination cache policy keyed by category + locale.
    expect(await view.findByText('Answer Three')).toBeInTheDocument()
    expect(view.getByText('Answer One')).toBeInTheDocument()
  })
})
