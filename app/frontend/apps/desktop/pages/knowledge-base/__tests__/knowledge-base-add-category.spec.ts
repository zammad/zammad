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
const NEW_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

const category = (id: string, title: string) => ({
  id,
  title,
  categoryIcon: 'folder',
  iconSet: 'FontAwesome',
  visibility: EnumKnowledgeBaseVisibility.Published,
  translationMissing: false,
  answerCount: 0,
  subcategoryCount: 0,
  position: 0,
  isDeletable: true,
  policy: { update: true, destroy: true, createSubcategory: true },
})

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
  // What the root category's listing reports. Mutable so an example can state what it sees once a
  //   sub-category was created under it.
  let rootChildren: ReturnType<typeof category>[]

  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })

    mockKnowledgeBaseEditorAccess()

    rootChildren = []

    // Answered per browsed category: the knowledge base root lists the one category, the category
    //   itself lists whatever was created under it.
    mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => {
      if (categoryId !== CATEGORY_ID) {
        return {
          knowledgeBaseCategorySubcategories: {
            category: null,
            subcategories: [category(CATEGORY_ID, 'Root Category')],
          },
        }
      }

      return {
        knowledgeBaseCategorySubcategories: {
          category: {
            ...category(CATEGORY_ID, 'Root Category'),
            breadcrumb: [{ id: CATEGORY_ID, title: 'Root Category', categoryIcon: 'folder' }],
          },
          subcategories: rootChildren,
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

    // A top level category has no parent to open — its siblings are the localized root listing,
    //   which is where the add card was clicked, so the user stays put.
    expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us')
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

  describe('from a category card', () => {
    const mockParentOptions = (options = [{ value: 1, label: 'Root Category' }]) =>
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            parentId: { options },
            categoryIcon: { initialValue: 'f0f6' },
          },
        },
      })

    const openAddSubcategory = async () => {
      const view = await visitView('/knowledge-base')

      await view.events.click(await view.findByRole('button', { name: 'Category actions' }))

      // The click handler sits on the item's button, not on the `menuitem` wrapper.
      await view.events.click(await view.findByText('Add sub-category'))

      return view
    }

    it('opens the category flyout with the category preselected as the parent', async () => {
      mockPermissions(['knowledge_base.editor'])
      mockParentOptions()

      const view = await openAddSubcategory()

      // One add mode, so the heading stays generic — the parent field is what tells the user
      //   under which category the new category will be created.
      expect(
        await view.findByRole('heading', { level: 2, name: 'Add category' }),
      ).toBeInTheDocument()

      const parentField = within(await view.findByTestId('field-treeselect'))

      await waitFor(() => {
        expect(parentField.getByRole('listitem')).toHaveTextContent('Root Category')
      })

      // A seed, not a lock: a mis-click stays correctable inside the flyout.
      expect(view.getByLabelText('Parent category')).toBeEnabled()
    })

    it('creates the new category under the parent category', async () => {
      mockPermissions(['knowledge_base.editor'])
      mockParentOptions()

      const view = await openAddSubcategory()

      await view.events.type(await view.findByLabelText('Title'), 'Printers')
      await view.events.click(view.getByRole('button', { name: 'Create' }))

      const calls = await waitForKnowledgeBaseCategoryAddMutationCalls()

      expect(calls.at(-1)?.variables).toMatchObject({
        input: {
          title: 'Printers',
          parentId: CATEGORY_ID,
        },
        locale: 'en-us',
      })
    })

    // Without this the user is left on the page they added from, where the category they just
    //   created is not listed — it belongs to the tile's category, not to this one.
    it('opens the parent category with the new sub-category listed', async () => {
      mockPermissions(['knowledge_base.editor'])
      mockParentOptions()

      const view = await openAddSubcategory()

      // What the parent's listing reports once the sub-category exists.
      rootChildren = [category(NEW_CATEGORY_ID, 'Printers')]

      await view.events.type(await view.findByLabelText('Title'), 'Printers')
      await view.events.click(view.getByRole('button', { name: 'Create' }))

      await waitForKnowledgeBaseCategoryAddMutationCalls()

      await waitFor(() => {
        expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us/category/1')
      })

      expect(await view.findByText('Printers')).toBeInTheDocument()
    })

    // The preselected parent is a seed the user may correct, so the submitted parent decides where
    //   the user ends up — not the tile the flyout was opened from.
    it('opens the parent picked in the treeselect, not the tile it came from', async () => {
      mockPermissions(['knowledge_base.editor'])
      mockParentOptions([
        { value: 1, label: 'Root Category' },
        { value: 3, label: 'Other Category' },
      ])

      const view = await openAddSubcategory()

      await view.events.type(await view.findByLabelText('Title'), 'Printers')

      await view.events.click(view.getByLabelText('Parent category'))
      const option = await view.findByRole('option', { name: 'Other Category' })
      await view.events.click(option.firstChild as Element)

      await view.events.click(view.getByRole('button', { name: 'Create' }))

      await waitForKnowledgeBaseCategoryAddMutationCalls()

      await waitFor(() => {
        expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us/category/3')
      })
    })

    it('does not offer it without create access to the category', async () => {
      mockPermissions(['knowledge_base.editor'])

      mockKnowledgeBaseCategorySubcategoriesQuery({
        knowledgeBaseCategorySubcategories: {
          category: null,
          subcategories: [
            {
              ...category(CATEGORY_ID, 'Root Category'),
              policy: { update: true, destroy: true, createSubcategory: false },
            },
          ],
        },
      })

      const view = await visitView('/knowledge-base')

      await view.events.click(await view.findByRole('button', { name: 'Category actions' }))

      expect(await view.findByText('Edit category')).toBeInTheDocument()
      expect(view.queryByText('Add sub-category')).not.toBeInTheDocument()
    })
  })
})
