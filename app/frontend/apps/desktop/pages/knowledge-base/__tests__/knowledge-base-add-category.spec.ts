// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { waitForKnowledgeBaseCategoryAddMutationCalls } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseCategoryAdd.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

// Adding a top level category is gated by the knowledge base's own policy, so each example
//   states the access it is about.
const mockKnowledgeBaseEditorAccess = (editor = true) =>
  mockKnowledgeBaseQuery({
    knowledgeBase: {
      id: convertToGraphQLId('KnowledgeBase', 1),
      title: 'My Knowledge Base',
      iconset: 'default',
      isPubliclyAvailable: true,
      isVisiblePublicly: true,
      policy: { update: editor },
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

describe('knowledge base add category card', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })

    mockKnowledgeBaseEditorAccess()

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

  it('offers adding a category to a knowledge base editor', async () => {
    mockPermissions(['knowledge_base.editor'])

    const view = await visitView('/knowledge-base')

    // The card's button is the one carrying visible text; the toolbar's is icon-only
    //   and takes its accessible name from a tooltip.
    expect(await view.findByText('Add category')).toBeInTheDocument()
  })

  it('opens the category flyout from the add card', async () => {
    mockPermissions(['knowledge_base.editor'])

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          parentId: {
            options: [{ value: 42, label: 'Hardware' }],
          },
        },
      },
    })

    const view = await visitView('/knowledge-base')

    await view.events.click(await view.findByText('Add category'))

    expect(await view.findByRole('heading', { level: 2, name: 'Add category' })).toBeInTheDocument()

    expect(await view.findByLabelText('Title')).toBeInTheDocument()
    expect(view.getByLabelText('Parent category')).toBeInTheDocument()
  })

  it('saves the new category and closes the flyout', async () => {
    mockPermissions(['knowledge_base.editor'])

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          parentId: { options: [{ value: 42, label: 'Hardware' }] },
          categoryIcon: { initialValue: 'f0f6' },
        },
      },
    })

    const view = await visitView('/knowledge-base')

    await view.events.click(await view.findByText('Add category'))

    await view.events.type(await view.findByLabelText('Title'), 'Printers')
    await view.events.click(view.getByRole('button', { name: 'Create' }))

    const calls = await waitForKnowledgeBaseCategoryAddMutationCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      input: {
        title: 'Printers',
      },
      locale: 'en-us',
    })

    await waitFor(() => {
      expect(
        view.queryByRole('heading', { level: 2, name: 'Add category' }),
      ).not.toBeInTheDocument()
    })
  })

  // The mocked IntersectionObserver never reports, so `useElementVisibility` stays
  //   false — which is exactly the out-of-view state the toolbar action covers, and
  //   the right way to fail open when visibility cannot be determined.
  it('falls back to the floating toolbar while the add card is out of view', async () => {
    mockPermissions(['knowledge_base.editor'])

    const view = await visitView('/knowledge-base')

    const toolbar = within(
      await view.findByRole('toolbar', { name: 'Knowledge base actions' }),
    ).getByRole('button', { name: 'Add category' })

    await view.events.click(toolbar)

    expect(await view.findByRole('heading', { level: 2, name: 'Add category' })).toBeInTheDocument()
  })

  // Gated by the knowledge base policy rather than the global permission: a granular editor
  //   who is only a reader of the base gets the same answer as a plain reader.
  it('does not offer adding a category without editor access to the knowledge base', async () => {
    mockPermissions(['knowledge_base.reader'])
    mockKnowledgeBaseEditorAccess(false)

    const view = await visitView('/knowledge-base')

    expect(await view.findByText('Root Category')).toBeInTheDocument()

    await waitFor(() => {
      expect(view.queryByText('Add category')).not.toBeInTheDocument()
    })

    expect(
      within(view.getByRole('toolbar', { name: 'Knowledge base actions' })).queryByRole('button', {
        name: 'Add category',
      }),
    ).not.toBeInTheDocument()
  })

  it('tells a reader without any categories that the knowledge base is empty', async () => {
    mockPermissions(['knowledge_base.reader'])
    mockKnowledgeBaseEditorAccess(false)

    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: { category: null, subcategories: [] },
    })

    const view = await visitView('/knowledge-base')

    expect(await view.findByText('No knowledge base content is available yet.')).toBeInTheDocument()
  })
})
