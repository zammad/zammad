// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { KnowledgeBaseCategoryDeleteDocument } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseCategoryDelete.api.ts'
import {
  mockKnowledgeBaseCategoryDeleteMutation,
  waitForKnowledgeBaseCategoryDeleteMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseCategoryDelete.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'

const ROOT_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

const category = (id: string, title: string, isDeletable = true) => ({
  id,
  title,
  categoryIcon: 'f115',
  iconSet: 'FontAwesome',
  visibility: EnumKnowledgeBaseVisibility.Published,
  translationMissing: false,
  answerCount: 0,
  subcategoryCount: 0,
  position: 0,
  isDeletable,
  policy: { update: true, destroy: true, createSubcategory: true },
})

describe('knowledge base delete category', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })
    mockPermissions(['knowledge_base.editor'])

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        title: 'My Knowledge Base',
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

    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: 0,
        edges: [],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })
  })

  const mockListing = (rootDeletable = true) => {
    mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => {
      if (categoryId === ROOT_CATEGORY_ID) {
        return {
          knowledgeBaseCategorySubcategories: {
            category: {
              ...category(ROOT_CATEGORY_ID, 'Root Category', rootDeletable),
              breadcrumb: [{ id: ROOT_CATEGORY_ID, title: 'Root Category', categoryIcon: 'f115' }],
            },
            subcategories: [category(CHILD_CATEGORY_ID, 'Child Category')],
          },
        }
      }

      if (categoryId === CHILD_CATEGORY_ID) {
        return {
          knowledgeBaseCategorySubcategories: {
            category: {
              ...category(CHILD_CATEGORY_ID, 'Child Category'),
              breadcrumb: [
                { id: ROOT_CATEGORY_ID, title: 'Root Category', categoryIcon: 'f115' },
                { id: CHILD_CATEGORY_ID, title: 'Child Category', categoryIcon: 'f115' },
              ],
            },
            subcategories: [],
          },
        }
      }

      return {
        knowledgeBaseCategorySubcategories: {
          category: null,
          subcategories: [category(ROOT_CATEGORY_ID, 'Root Category', rootDeletable)],
        },
      }
    })
  }

  const deleteMutationCallCount = () =>
    getGraphQLMockCalls(KnowledgeBaseCategoryDeleteDocument).length

  const clickDeleteOnCard = async (view: Awaited<ReturnType<typeof visitView>>) => {
    await view.events.click(await view.findByRole('button', { name: 'Category actions' }))

    // The click handler sits on the item's button, not on the `menuitem` wrapper.
    await view.events.click(await view.findByText('Delete category'))
  }

  const confirmDeletion = async (view: Awaited<ReturnType<typeof visitView>>) => {
    await view.events.click(
      within(await view.findByRole('dialog')).getByRole('button', { name: 'Delete object' }),
    )
  }

  describe('from a category card', () => {
    it('refuses a non-empty category without asking the server', async () => {
      mockListing(false)

      const view = await visitView('/knowledge-base')

      await clickDeleteOnCard(view)

      expect(await view.findByText('Cannot delete category')).toBeInTheDocument()
      expect(
        view.getByText('Delete all child categories and answers, then try again.'),
      ).toBeInTheDocument()

      // An informational dialog only: there is nothing to cancel.
      const dialog = within(view.getByRole('dialog'))
      expect(dialog.queryByRole('button', { name: 'Cancel & go back' })).not.toBeInTheDocument()

      await view.events.click(dialog.getByRole('button', { name: 'OK' }))

      expect(deleteMutationCallCount()).toBe(0)
    })

    it('deletes an empty category after confirmation and stays put', async () => {
      mockListing()

      const view = await visitView('/knowledge-base')

      mockKnowledgeBaseCategoryDeleteMutation({
        knowledgeBaseCategoryDelete: { success: true, errors: null },
      })

      await clickDeleteOnCard(view)

      expect(
        await view.findByText('Do you really want to delete "Root Category"?'),
      ).toBeInTheDocument()

      await confirmDeletion(view)

      const calls = await waitForKnowledgeBaseCategoryDeleteMutationCalls()
      expect(calls.at(-1)?.variables).toEqual({ categoryId: ROOT_CATEGORY_ID })

      // Deleting from a tile in the listing does not navigate anywhere — the URL stays
      //   at the localised root the section guard resolved on entry.
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us')
    })

    it('sends nothing when the confirmation is cancelled', async () => {
      mockListing()

      const view = await visitView('/knowledge-base')

      await clickDeleteOnCard(view)

      await view.events.click(
        within(await view.findByRole('dialog')).getByRole('button', { name: 'Cancel & go back' }),
      )

      await waitFor(() => {
        expect(view.queryByRole('dialog')).not.toBeInTheDocument()
      })

      expect(deleteMutationCallCount()).toBe(0)
    })

    it('surfaces a backend refusal through the cannot-delete dialog', async () => {
      mockListing()

      const view = await visitView('/knowledge-base')

      // The client check passed, but the category gained content in the meantime — the
      //   backend answers with the user error from ActiveRecord::DeleteRestrictionError.
      mockKnowledgeBaseCategoryDeleteMutation({
        knowledgeBaseCategoryDelete: {
          success: null,
          errors: [
            { message: 'Delete all child categories and answers, then try again.', field: null },
          ],
        },
      })

      await clickDeleteOnCard(view)
      await confirmDeletion(view)

      expect(await view.findByText('Cannot delete category')).toBeInTheDocument()

      await view.events.click(within(view.getByRole('dialog')).getByRole('button', { name: 'OK' }))

      // The category is still there, so its tile must not have been evicted — the refusal
      //   arrives as payload errors, which Apollo still routes through the update callback.
      expect(view.getByText('Root Category')).toBeInTheDocument()
    })
  })

  describe('from the header actions', () => {
    const deleteOpenedCategory = async (view: Awaited<ReturnType<typeof visitView>>) => {
      const header = within(await view.findByTestId('knowledge-base-header-full'))
      await view.events.click(header.getByRole('button', { name: 'Additional actions' }))
      await view.events.click(await view.findByText('Delete category'))

      await confirmDeletion(view)
      await waitForKnowledgeBaseCategoryDeleteMutationCalls()
    }

    it('navigates to the parent after deleting the opened category', async () => {
      mockListing()

      const view = await visitView('/knowledge-base/locale/en-us/category/2')

      mockKnowledgeBaseCategoryDeleteMutation({
        knowledgeBaseCategoryDelete: { success: true, errors: null },
      })

      await deleteOpenedCategory(view)

      await waitFor(() => {
        expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us/category/1')
      })
    })

    it('navigates to the localised root after deleting an opened top level category', async () => {
      mockListing()

      const view = await visitView('/knowledge-base/locale/en-us/category/1')

      mockKnowledgeBaseCategoryDeleteMutation({
        knowledgeBaseCategoryDelete: { success: true, errors: null },
      })

      await deleteOpenedCategory(view)

      await waitFor(() => {
        expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us')
      })
    })
  })
})
