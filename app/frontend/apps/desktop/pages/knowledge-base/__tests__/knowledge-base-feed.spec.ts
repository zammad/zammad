// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import type { KnowledgeBaseAnswerQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswerQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'
import {
  mockKnowledgeBaseFeedQuery,
  waitForKnowledgeBaseFeedQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseFeed.mocks.ts'

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

const knowledgeBasePath = '/api/v1/knowledge_bases/1/en-us/feed?token=abc'
const categoryPath = '/api/v1/knowledge_bases/1/categories/1/en-us/feed?token=abc'

describe('knowledge base feed', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active: true, http_type: 'https', fqdn: 'zammad.example.org' })
    mockPermissions(['knowledge_base.reader'])

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        translation: { title: 'My Knowledge Base' },
        showFeedIcon: true,
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

    mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => {
      if (categoryId === CATEGORY_ID) {
        return {
          knowledgeBaseCategorySubcategories: {
            category: {
              id: CATEGORY_ID,
              breadcrumb: [{ id: CATEGORY_ID, translation: { title: 'Some Category' } }],
            },
            subcategories: [],
          },
        }
      }

      return {
        knowledgeBaseCategorySubcategories: {
          category: null,
          subcategories: [
            {
              id: CATEGORY_ID,
              title: 'Some Category',
              categoryIcon: 'f115',
              iconSet: 'FontAwesome',
              visibility: EnumKnowledgeBaseVisibility.Published,
              answerCount: 0,
              subcategoryCount: 0,
              position: 0,
            },
          ],
        },
      }
    })

    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: 0,
        edges: [],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })
  })

  const openFeedFlyout = async (path: `/${string}`) => {
    const view = await visitView(path)

    await waitFor(() => {
      expect(view).toHaveCurrentUrl(path)
    })

    // Both headers are mounted (full and compact), so pick the first menu button.
    const menuButtons = await view.findAllByRole('button', { name: 'Additional actions' })
    await view.events.click(menuButtons[0])

    await view.events.click(await view.findByRole('button', { name: 'Set up RSS feed' }))

    return view
  }

  it('offers both feeds while a category is open', async () => {
    mockKnowledgeBaseFeedQuery({
      knowledgeBaseFeed: { knowledgeBasePath, categoryPath },
    })

    const view = await openFeedFlyout('/knowledge-base/locale/en-us/category/1')

    const calls = await waitForKnowledgeBaseFeedQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({ categoryId: CATEGORY_ID, locale: 'en-us' })

    expect(await view.findByLabelText('Category feed')).toHaveValue(
      `https://zammad.example.org${categoryPath}`,
    )
  })

  // Like the old interface, an open answer offers the feed of its own category.
  it('offers both feeds while an answer is open', async () => {
    mockKnowledgeBaseAnswerQuery({
      knowledgeBaseAnswer: {
        id: convertToGraphQLId('KnowledgeBase::Answer', 5),
        translation: {
          title: 'Some Knowledge Base Answer',
        },
        visibility: EnumKnowledgeBaseVisibility.Published,
        category: {
          id: CATEGORY_ID,
          breadcrumb: [{ id: CATEGORY_ID, translation: { title: 'Some Category' } }],
        },
      },
    } as KnowledgeBaseAnswerQuery)

    mockKnowledgeBaseFeedQuery({
      knowledgeBaseFeed: { knowledgeBasePath, categoryPath },
    })

    const view = await openFeedFlyout('/knowledge-base/locale/en-us/answer/5')

    const calls = await waitForKnowledgeBaseFeedQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({ categoryId: CATEGORY_ID, locale: 'en-us' })

    expect(await view.findByLabelText('Category feed')).toHaveValue(
      `https://zammad.example.org${categoryPath}`,
    )
  })

  it('offers only the knowledge base feed at the root', async () => {
    mockKnowledgeBaseFeedQuery({
      knowledgeBaseFeed: { knowledgeBasePath, categoryPath: null },
    })

    const view = await openFeedFlyout('/knowledge-base/locale/en-us')

    const calls = await waitForKnowledgeBaseFeedQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({ categoryId: undefined, locale: 'en-us' })

    // Flyout title + KB feed URL field.
    expect(await view.findAllByLabelText('Knowledge base feed')).toHaveLength(2)

    expect(view.queryByLabelText('Category feed')).not.toBeInTheDocument()
  })
})
