// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

// The view wires the toolbar Knowledge base actions to scrollIntoView on the content
//   container; mock it so the calls can be asserted without a real scroller.
const scrollIntoViewMock = vi.hoisted(() => vi.fn())

vi.mock('#shared/utils/dom.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('#shared/utils/dom.ts')>()),
  scrollIntoView: scrollIntoViewMock,
}))

describe('knowledge base floating toolbar', () => {
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

  it('renders the scroll toolbar with both scroll actions', async () => {
    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(CATEGORY_ID)}`,
    )

    const toolbar = await view.findByRole('toolbar', { name: 'Knowledge base actions' })

    expect(within(toolbar).getByRole('button', { name: 'Scroll to start' })).toBeVisible()
    expect(within(toolbar).getByRole('button', { name: 'Scroll to end' })).toBeVisible()
  })

  it('scrolls the content container to the end when scroll to end is clicked', async () => {
    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(CATEGORY_ID)}`,
    )

    const toolbar = await view.findByRole('toolbar', { name: 'Knowledge base actions' })

    await view.events.click(within(toolbar).getByRole('button', { name: 'Scroll to end' }))

    expect(scrollIntoViewMock).toHaveBeenLastCalledWith(expect.anything(), 'end', {
      behavior: 'instant',
    })
  })

  it('scrolls the content container to the start when scroll to start is clicked', async () => {
    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(CATEGORY_ID)}`,
    )

    const toolbar = await view.findByRole('toolbar', { name: 'Knowledge base actions' })

    await view.events.click(within(toolbar).getByRole('button', { name: 'Scroll to start' }))

    expect(scrollIntoViewMock).toHaveBeenLastCalledWith(expect.anything(), 'start', {
      behavior: 'instant',
    })
  })
})
