// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

describe('knowledge base add category card', () => {
  beforeEach(() => {
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
        currentLocale: {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          systemLocale: { id: '1', locale: 'en-us' },
        },
      },
    })

    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: {
        category: null,
        subcategories: [
          {
            id: CATEGORY_ID,
            title: 'Root Category',
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
            answerCount: 0,
            subcategoryCount: 0,
            position: 0,
          },
        ],
      },
    })

    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: 0,
        edges: [],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })
  })

  // TODO: Will be implemented soon
  //  oxlint-disable no-disabled-tests
  it.skip('offers adding a category to a knowledge base editor', async () => {
    mockPermissions(['knowledge_base.editor'])

    const view = await visitView('/knowledge-base')

    expect(await view.findByRole('button', { name: 'Add category' })).toBeInTheDocument()
  })

  it('does not offer adding a category without the editor permission', async () => {
    mockPermissions(['knowledge_base.reader'])

    const view = await visitView('/knowledge-base')

    expect(await view.findByText('Root Category')).toBeInTheDocument()

    await waitFor(() => {
      expect(view.queryByRole('button', { name: 'Add category' })).not.toBeInTheDocument()
    })
  })

  it('tells a reader without any categories that the knowledge base is empty', async () => {
    mockPermissions(['knowledge_base.reader'])

    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: { category: null, subcategories: [] },
    })

    const view = await visitView('/knowledge-base')

    expect(await view.findByText('No knowledge base content is available yet.')).toBeInTheDocument()
  })
})
