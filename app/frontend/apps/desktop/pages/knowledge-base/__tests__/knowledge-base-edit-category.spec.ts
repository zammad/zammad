// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { waitForKnowledgeBaseCategoryUpdateMutationCalls } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseCategoryUpdate.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'

const ROOT_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

const category = (id: string, title: string, editor = true) => ({
  id,
  title,
  categoryIcon: 'f115',
  iconSet: 'FontAwesome',
  visibility: EnumKnowledgeBaseVisibility.Published,
  translationMissing: false,
  answerCount: 0,
  subcategoryCount: 0,
  position: 0,
  policy: { update: editor, destroy: editor, createSubcategory: editor },
})

// The action menus are gated by each category's own policy, so the access under test is
//   stated per example rather than assumed from the global permission.
const mockCategoryAccess = (editor = true) =>
  mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => {
    if (categoryId === ROOT_CATEGORY_ID) {
      return {
        knowledgeBaseCategorySubcategories: {
          category: {
            ...category(ROOT_CATEGORY_ID, 'Root Category', editor),
            breadcrumb: [{ id: ROOT_CATEGORY_ID, title: 'Root Category', categoryIcon: 'f115' }],
          },
          subcategories: [category(CHILD_CATEGORY_ID, 'Child Category', editor)],
        },
      }
    }

    return {
      knowledgeBaseCategorySubcategories: {
        category: null,
        subcategories: [category(ROOT_CATEGORY_ID, 'Root Category', editor)],
      },
    }
  })

describe('knowledge base edit category', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        title: 'My Knowledge Base',
        footerNote: 'Footer',
        iconset: 'default',
        isPubliclyAvailable: true,
        isVisiblePublicly: true,
        policy: { update: true },
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

    mockCategoryAccess()

    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: 0,
        edges: [],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          parentId: {
            options: [{ value: 42, label: 'Hardware' }],
          },
        },
      },
    })
  })

  describe('from a category card', () => {
    it('edits the card own category', async () => {
      mockPermissions(['knowledge_base.editor'])

      const view = await visitView('/knowledge-base')

      await view.events.click(await view.findByRole('button', { name: 'Category actions' }))

      // The click handler sits on the item's button, not on the `menuitem` wrapper.
      await view.events.click(await view.findByText('Edit category'))

      expect(
        await view.findByRole('heading', { level: 2, name: 'Edit category' }),
      ).toBeInTheDocument()

      // Title and icon are prefilled from the card, the form updater resolves neither.
      expect(await view.findByLabelText('Title')).toHaveValue('Root Category')
    })

    it('saves the edited category and closes the flyout', async () => {
      mockPermissions(['knowledge_base.editor'])

      const view = await visitView('/knowledge-base')

      await view.events.click(await view.findByRole('button', { name: 'Category actions' }))
      await view.events.click(await view.findByText('Edit category'))

      const title = await view.findByLabelText('Title')
      await view.events.clear(title)
      await view.events.type(title, 'Printers')

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const calls = await waitForKnowledgeBaseCategoryUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toMatchObject({
        categoryId: ROOT_CATEGORY_ID,
        input: {
          title: 'Printers',
        },
        locale: 'en-us',
      })

      await waitFor(() => {
        expect(
          view.queryByRole('heading', { level: 2, name: 'Edit category' }),
        ).not.toBeInTheDocument()
      })
    })

    // Gated per record now: a granular editor without access to this category gets the same
    //   answer as a plain reader, which the policy fields carry.
    it('does not offer the menu without access to the category', async () => {
      mockPermissions(['knowledge_base.reader'])
      mockCategoryAccess(false)

      const view = await visitView('/knowledge-base')

      expect(await view.findByText('Root Category')).toBeInTheDocument()

      await waitFor(() => {
        expect(view.queryByRole('button', { name: 'Category actions' })).not.toBeInTheDocument()
      })
    })
  })

  describe('from the header actions', () => {
    it('edits the opened category', async () => {
      mockPermissions(['knowledge_base.editor'])

      const view = await visitView('/knowledge-base/locale/en-us/category/1')

      const header = within(await view.findByTestId('knowledge-base-header-full'))

      await view.events.click(header.getByRole('button', { name: 'Additional actions' }))

      // The click handler sits on the item's button, not on the `menuitem` wrapper.
      await view.events.click(await view.findByText('Edit category'))

      expect(
        await view.findByRole('heading', { level: 2, name: 'Edit category' }),
      ).toBeInTheDocument()

      expect(await view.findByLabelText('Title')).toHaveValue('Root Category')
    })

    it('offers editing the knowledge base root when no category is opened', async () => {
      mockPermissions(['knowledge_base.editor'])

      const view = await visitView('/knowledge-base')

      const header = within(await view.findByTestId('knowledge-base-header-full'))

      await view.events.click(header.getByRole('button', { name: 'Additional actions' }))

      expect(await view.findByText('Edit knowledge base')).toBeInTheDocument()
    })

    it('does not offer editing the knowledge base root without root editor access', async () => {
      mockPermissions(['knowledge_base.reader'])
      mockKnowledgeBaseQuery({
        knowledgeBase: {
          id: convertToGraphQLId('KnowledgeBase', 1),
          title: 'My Knowledge Base',
          footerNote: 'Footer',
          iconset: 'default',
          isPubliclyAvailable: true,
          isVisiblePublicly: true,
          policy: { update: false },
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

      const view = await visitView('/knowledge-base')

      const header = within(await view.findByTestId('knowledge-base-header-full'))

      await waitFor(() => {
        expect(header.queryByRole('button', { name: 'Additional actions' })).not.toBeInTheDocument()
      })
    })

    it('does not offer the menu without access to the category', async () => {
      mockPermissions(['knowledge_base.reader'])
      mockCategoryAccess(false)

      const view = await visitView('/knowledge-base/locale/en-us/category/1')

      const header = within(await view.findByTestId('knowledge-base-header-full'))

      await waitFor(() => {
        expect(header.queryByRole('button', { name: 'Additional actions' })).not.toBeInTheDocument()
      })
    })
  })
})
