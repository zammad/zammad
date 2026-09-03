// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { onScopeDispose } from 'vue'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswerQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'
import { mockLinkListQuery } from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'

// How many of each view are alive: the composables below run once per instance, in the instance's
//   own scope - so a view that is torn down counts as disposed, while one that is only deactivated
//   (kept in a cache, or dropped from one and left behind) does not.
const browse = vi.hoisted(() => ({ created: 0, disposed: 0 }))
const answer = vi.hoisted(() => ({ created: 0, disposed: 0 }))

vi.mock(
  '#desktop/pages/knowledge-base/composables/useKnowledgeBaseCategorySubcategories.ts',
  async (importOriginal) => {
    const original =
      await importOriginal<
        typeof import('#desktop/pages/knowledge-base/composables/useKnowledgeBaseCategorySubcategories.ts')
      >()

    return {
      ...original,
      useKnowledgeBaseCategorySubcategories: (
        ...args: Parameters<typeof original.useKnowledgeBaseCategorySubcategories>
      ) => {
        browse.created += 1
        onScopeDispose(() => {
          browse.disposed += 1
        })

        return original.useKnowledgeBaseCategorySubcategories(...args)
      },
    }
  },
)

vi.mock(
  '#desktop/pages/knowledge-base/composables/useKnowledgeBaseAnswer.ts',
  async (importOriginal) => {
    const original =
      await importOriginal<
        typeof import('#desktop/pages/knowledge-base/composables/useKnowledgeBaseAnswer.ts')
      >()

    return {
      ...original,
      useKnowledgeBaseAnswer: (...args: Parameters<typeof original.useKnowledgeBaseAnswer>) => {
        answer.created += 1
        onScopeDispose(() => {
          answer.disposed += 1
        })

        return original.useKnowledgeBaseAnswer(...args)
      },
    }
  },
)

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 1)

describe('knowledge base section view lifecycle', () => {
  beforeEach(() => {
    browse.created = 0
    browse.disposed = 0
    answer.created = 0
    answer.disposed = 0

    mockApplicationConfig({ kb_active: true })

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        translation: { title: 'My Knowledge Base' },
        iconset: 'default',
        isPubliclyAvailable: false,
        isVisiblePublicly: false,
        kbLocales: [
          {
            id: convertToGraphQLId('KnowledgeBase::Locale', 1),
            primary: true,
            systemLocale: { id: '1', locale: 'en-us', name: 'English (United States)' },
          },
        ],
        currentLocale: {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          systemLocale: { id: '1', locale: 'en-us' },
        },
      },
    })

    mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => ({
      knowledgeBaseCategorySubcategories: {
        category: categoryId
          ? {
              id: CATEGORY_ID,
              breadcrumb: [{ id: CATEGORY_ID, translation: { title: 'Root Category' } }],
            }
          : null,
        subcategories: categoryId
          ? []
          : [
              {
                id: CATEGORY_ID,
                translation: { title: 'Root Category' },
                categoryIcon: 'f115',
                iconSet: 'FontAwesome',
                visibility: EnumKnowledgeBaseVisibility.Published,
                answerCount: 0,
                subcategoryCount: 0,
                position: 0,
              },
            ],
      },
    }))

    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: 0,
        edges: [],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })

    mockKnowledgeBaseAnswerQuery({
      knowledgeBaseAnswer: {
        id: ANSWER_ID,
        category: {
          id: CATEGORY_ID,
          breadcrumb: [{ id: CATEGORY_ID, translation: { title: 'Root Category' } }],
        },
        translation: {
          id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
          title: 'Getting Started',
          navigation: null,
        },
        visibilitySchedules: [],
      },
    })

    // The reader's sidebar lists related tickets; left to the auto-mock it generates them endlessly.
    mockLinkListQuery({ linkList: [] })
  })

  // One page of the section alive at a time: the page on screen is cached so it survives leaving
  //   the tab, and the one before it is torn down (see LayoutSectionPages). The sum is the
  //   assertion that matters - a page deactivated *and* dropped from a cache leaves `created`
  //   climbing while `disposed` stands still, and the sum passes one, which is what the `max="1"`
  //   cache these pages used to have produced.
  it('keeps one page of the section alive at a time', async () => {
    const alive = () => browse.created - browse.disposed + (answer.created - answer.disposed)

    const view = await visitView('/knowledge-base/locale/en-us')

    await waitFor(() => {
      expect(browse.created, 'the browse view is up').toBe(1)
    })

    const router = getTestRouter()

    // The root and the category are the same component, so this reuses the instance - patching,
    //   not a cache.
    await router.push('/knowledge-base/locale/en-us/category/1')
    await waitFor(() => {
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us/category/1')
    })

    expect(browse, 'root and category share the instance').toMatchObject({
      created: 1,
      disposed: 0,
    })

    await router.push('/knowledge-base/locale/en-us/answer/1')
    await waitFor(() => {
      expect(answer.created, 'the answer view is up').toBe(1)
    })

    await waitFor(() => {
      expect(alive(), 'on an answer, with the browse page gone').toBe(1)
    })

    await router.push('/knowledge-base/locale/en-us/category/1')
    await waitFor(() => {
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us/category/1')
    })

    await waitFor(() => {
      expect(alive(), 'back on the category, with the answer gone').toBe(1)
    })

    // Rebuilt, but rendered from the Apollo cache rather than skeletoned.
    expect(view.getAllByText('Root Category')).not.toHaveLength(0)
  })
})
