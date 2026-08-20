// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { within } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent, { initializePiniaStore } from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { FormUpdaterDocument } from '#shared/components/Form/graphql/queries/formUpdater.api.ts'
import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockKnowledgeBaseCategoryAddMutation,
  waitForKnowledgeBaseCategoryAddMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseCategoryAdd.mocks.ts'
import { waitForKnowledgeBaseCategoryUpdateMutationCalls } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseCategoryUpdate.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'

import KnowledgeBaseCategoryFlyout from '../KnowledgeBaseCategoryFlyout.vue'

const FLYOUT_NAME = 'knowledge-base-category'

const PARENT_ID = convertToGraphQLId('KnowledgeBase::Category', 42)

const KNOWLEDGE_BASE_ID = convertToGraphQLId('KnowledgeBase', 1)
const KB_LOCALE_ID = convertToGraphQLId('KnowledgeBase::Locale', 1)

const CATEGORY = {
  id: convertToGraphQLId('KnowledgeBase::Category', 7),
  title: 'Hardware',
  categoryIcon: 'f0f6',
}

// The permission matrix only exists with granular permissions on, so the updater omits the
//   field entirely otherwise — and the schema keeps it hidden until it arrives.
const PERMISSIONS_FIELD = {
  show: true,
  permissionRows: [
    {
      roleId: '1',
      roleName: 'Admin',
      inheritedAccess: null,
      allowedAccesses: ['editor', 'reader', 'none'],
    },
    {
      roleId: '2',
      roleName: 'Agent',
      inheritedAccess: 'reader',
      allowedAccesses: ['reader', 'none'],
    },
  ],
  initialValue: { 1: 'editor', 2: 'reader' },
}

// The top level is not an option — an empty selection means it — so the updater only ever
//   offers real categories, and sends no initial value when the parent is the top level.
const updaterCallCount = () => getGraphQLMockCalls(FormUpdaterDocument).length

const mockParentOptions = (
  initialValue?: number,
  options: { permissions?: boolean } = { permissions: true },
) => {
  mockFormUpdaterQuery({
    formUpdater: {
      fields: {
        parentId: {
          ...(initialValue === undefined ? {} : { initialValue }),
          options: [
            { value: 42, label: 'Hardware' },
            { value: 43, label: 'Software' },
          ],
        },
        categoryIcon: {
          initialValue: 'f0f6',
        },
        ...(options.permissions ? { permissions: PERMISSIONS_FIELD } : {}),
      },
    },
  })
}

// The flyout takes the knowledge base it saves into, and the locale it writes the title
//   in, from the store — not from its props.
const mockKnowledgeBase = () => {
  mockKnowledgeBaseQuery({
    knowledgeBase: {
      id: KNOWLEDGE_BASE_ID,
      currentLocale: {
        id: KB_LOCALE_ID,
        systemLocale: { id: '1', locale: 'en-us' },
      },
    },
  })
}

const renderFlyout = (props: Record<string, unknown> = {}) => {
  initializePiniaStore()

  mockKnowledgeBase()

  return renderComponent(KnowledgeBaseCategoryFlyout, {
    props: {
      name: FLYOUT_NAME,
      ...props,
    },
    form: true,
    router: true,
    store: true,
    global: {
      stubs: {
        teleport: true,
      },
    },
  })
}

describe('KnowledgeBaseCategoryFlyout', () => {
  describe('when adding a category', () => {
    it('renders the category form', async () => {
      mockParentOptions()

      const wrapper = renderFlyout()

      expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent('Add category')

      expect(await wrapper.findByLabelText('Title')).toBeInTheDocument()
      expect(wrapper.getByLabelText('Icon')).toBeInTheDocument()
      expect(wrapper.getByLabelText('Parent category')).toBeInTheDocument()

      expect(wrapper.getByRole('button', { name: 'Create' })).toBeInTheDocument()
    })

    it('offers the parents resolved by the form updater', async () => {
      mockParentOptions()

      const wrapper = renderFlyout()

      await wrapper.events.click(await wrapper.findByLabelText('Parent category'))

      expect(await wrapper.findByRole('option', { name: 'Hardware' })).toBeInTheDocument()
      expect(wrapper.getByRole('option', { name: 'Software' })).toBeInTheDocument()
    })

    // No parent is the top level, so the field starts empty and has to be clearable to get
    //   back there.
    it('starts without a parent and lets a picked one be cleared', async () => {
      mockParentOptions()

      const wrapper = renderFlyout()

      await wrapper.events.click(await wrapper.findByLabelText('Parent category'))

      // The clear control only exists while something is selected, which makes it the readable
      //   proxy for "this category has a parent".
      expect(wrapper.queryByRole('button', { name: 'Clear selection' })).not.toBeInTheDocument()

      const option = await wrapper.findByRole('option', { name: 'Hardware' })
      await wrapper.events.click(option.firstChild as Element)

      await wrapper.events.click(await wrapper.findByRole('button', { name: 'Clear selection' }))

      expect(wrapper.queryByRole('button', { name: 'Clear selection' })).not.toBeInTheDocument()
    })

    describe('permissions matrix', () => {
      it('renders a row per role with the resolved access preselected', async () => {
        mockParentOptions()

        const wrapper = renderFlyout()

        const table = within(await wrapper.findByRole('table'))

        // One header row plus one per role.
        expect(table.getAllByRole('row')).toHaveLength(3)

        expect(wrapper.getByLabelText('Admin - Editor')).toBeChecked()
        expect(wrapper.getByLabelText('Agent - Reader')).toBeChecked()
        expect(wrapper.getByLabelText('Agent - Editor')).not.toBeChecked()
      })

      it('lets an access be picked', async () => {
        mockParentOptions()

        const wrapper = renderFlyout()

        await wrapper.events.click(await wrapper.findByLabelText('Agent - None'))

        expect(wrapper.getByLabelText('Agent - None')).toBeChecked()
        expect(wrapper.getByLabelText('Agent - Reader')).not.toBeChecked()
      })

      // Only the parent decides what is legal. A run triggered by the matrix itself would come
      //   back with a `value` that overwrites the selection the user just made.
      it('does not ask the form updater again when an access is picked', async () => {
        mockParentOptions()

        const wrapper = renderFlyout()

        const calls = await waitForFormUpdaterQueryCalls()
        const initialCount = calls.length

        await wrapper.events.click(await wrapper.findByLabelText('Agent - None'))

        // A parent change does re-resolve the matrix, so waiting for exactly one further call
        //   is what proves the access change queued none of its own.
        await wrapper.events.click(wrapper.getByLabelText('Parent category'))
        const option = await wrapper.findByRole('option', { name: 'Hardware' })
        await wrapper.events.click(option.firstChild as Element)

        await waitFor(() => {
          expect(calls).toHaveLength(initialCount + 1)
        })

        // The picked access still rides along in the payload — the whole form is sent, whoever
        //   triggered the run — so the updater can resolve the rows against it.
        expect(calls.at(-1)?.variables.data).toMatchObject({
          parentId: 42,
          permissions: { 1: 'editor', 2: 'none' },
        })
      })

      it('locks an access the role may not be given', async () => {
        mockParentOptions()

        const wrapper = renderFlyout()

        // Agent inherits reader, and the row offers only reader and none.
        expect(await wrapper.findByLabelText('Agent - Editor')).toBeDisabled()
        expect(wrapper.getByLabelText('Agent - Reader')).toBeEnabled()
        expect(wrapper.getByLabelText('Admin - Editor')).toBeEnabled()
      })

      // Without granular permissions the updater sends no `permissions` field at all, and the
      //   schema keeps it hidden rather than leaving it in its loading skeleton.
      it('stays hidden when the form updater does not resolve it', async () => {
        mockParentOptions(undefined, { permissions: false })

        const wrapper = renderFlyout()

        expect(await wrapper.findByLabelText('Title')).toBeInTheDocument()
        expect(wrapper.queryByRole('table')).not.toBeInTheDocument()
      })
    })

    it('asks the form updater to preselect the browsed category', async () => {
      mockParentOptions(42)

      renderFlyout({ parentId: PARENT_ID })

      const calls = await waitForFormUpdaterQueryCalls()

      expect(calls.at(-1)?.variables).toMatchObject({
        id: undefined,
        data: { parentId: 42 },
        meta: { initial: true },
      })
    })

    describe('saving', () => {
      it('creates the category in the browsed knowledge base and locale', async () => {
        mockParentOptions()

        const wrapper = renderFlyout()

        await wrapper.events.type(await wrapper.findByLabelText('Title'), 'Printers')
        await wrapper.events.click(wrapper.getByRole('button', { name: 'Create' }))

        const calls = await waitForKnowledgeBaseCategoryAddMutationCalls()

        expect(calls.at(-1)?.variables).toEqual({
          knowledgeBaseId: KNOWLEDGE_BASE_ID,
          // The locale of the call: the title is written into it and the response comes back in
          //   it, which is what the browsed page reads from the cache.
          locale: 'en-us',
          input: {
            categoryIcon: 'f0f6',
            title: 'Printers',
            // No parent is the top level, and the mutation has no other way to be told so.
            parentId: null,
            // The field holds an access per role id; the mutation wants a list, with the
            //   roles addressed by GraphQL id.
            permissions: [
              { roleId: convertToGraphQLId('Role', 1), access: 'editor' },
              { roleId: convertToGraphQLId('Role', 2), access: 'reader' },
            ],
          },
        })
      })

      // Only the parent decides what the updater resolves (the permission matrix inherits from
      //   it), so typing a title or picking an icon must not cost a round trip.
      it('re-runs the form updater for the parent only', async () => {
        mockParentOptions()

        const wrapper = renderFlyout()

        await waitFor(() => expect(updaterCallCount()).toBe(1))

        await wrapper.events.type(await wrapper.findByLabelText('Title'), 'Printers')

        // Text inputs trigger the updater 'delayed' (300ms), so outwait it before counting.
        await new Promise((resolve) => setTimeout(resolve, 500))
        expect(updaterCallCount(), 'title change does not trigger the updater').toBe(1)

        await wrapper.events.click(wrapper.getByLabelText('Parent category'))
        const option = await wrapper.findByRole('option', { name: 'Hardware' })
        await wrapper.events.click(option.firstChild as Element)

        await waitFor(() => {
          expect(updaterCallCount(), 'the parent does trigger it').toBe(2)
        })
      })

      it('sends the picked parent', async () => {
        mockParentOptions()

        const wrapper = renderFlyout()

        await wrapper.events.type(await wrapper.findByLabelText('Title'), 'Printers')

        await wrapper.events.click(wrapper.getByLabelText('Parent category'))
        const option = await wrapper.findByRole('option', { name: 'Hardware' })
        await wrapper.events.click(option.firstChild as Element)

        await wrapper.events.click(wrapper.getByRole('button', { name: 'Create' }))

        const calls = await waitForKnowledgeBaseCategoryAddMutationCalls()

        expect(calls.at(-1)?.variables.input).toMatchObject({ parentId: PARENT_ID })
      })

      // An empty list would drop the category's stored permissions, so "no matrix" has to
      //   mean "say nothing about permissions" instead.
      it('says nothing about permissions when the matrix never appeared', async () => {
        mockParentOptions(undefined, { permissions: false })

        const wrapper = renderFlyout()

        await wrapper.events.type(await wrapper.findByLabelText('Title'), 'Printers')
        await wrapper.events.click(wrapper.getByRole('button', { name: 'Create' }))

        const calls = await waitForKnowledgeBaseCategoryAddMutationCalls()

        expect(calls.at(-1)?.variables.input).not.toHaveProperty('permissions')
      })

      // The backend reports a duplicate title on the category's autosaved translation, so
      //   without remapping it the message would land on the form rather than the field.
      it('shows a title error on the title field', async () => {
        mockParentOptions()

        mockKnowledgeBaseCategoryAddMutation({
          knowledgeBaseCategoryAdd: {
            category: null,
            errors: [{ message: 'has to be unique', field: 'translations.title' }],
          },
        })

        const wrapper = renderFlyout()

        await wrapper.events.type(await wrapper.findByLabelText('Title'), 'Printers')
        await wrapper.events.click(wrapper.getByRole('button', { name: 'Create' }))

        expect(await wrapper.findByText('has to be unique')).toBeInTheDocument()

        // On the field itself, and not additionally on the form root — which is where a field
        //   name that cannot be resolved to a field ends up instead.
        const formNode = getNode('form-knowledge-base-category')!
        expect(formNode.find('title', 'name')?.context?.state.errors).toBe(true)
        expect(Object.values(formNode.store).filter((message) => message.type === 'error')).toEqual(
          [],
        )

        // Still on the form, so the failed title can be corrected.
        expect(wrapper.getByLabelText('Title')).toHaveValue('Printers')
      })
    })
  })

  describe('when editing a category', () => {
    it('renders the category form with the stored values', async () => {
      mockParentOptions(42)

      const wrapper = renderFlyout({ category: CATEGORY })

      expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent('Edit category')

      // Prefilled from the entity object: the form updater resolves neither.
      expect(await wrapper.findByLabelText('Title')).toHaveValue('Hardware')

      expect(wrapper.getByRole('button', { name: 'Update' })).toBeInTheDocument()
    })

    it('identifies the category to the form updater', async () => {
      mockParentOptions()

      renderFlyout({ category: CATEGORY })

      const calls = await waitForFormUpdaterQueryCalls()

      expect(calls.at(-1)?.variables).toMatchObject({ id: CATEGORY.id })
    })

    describe('saving', () => {
      it('updates the category, keeping its stored parent', async () => {
        mockParentOptions(42)

        const wrapper = renderFlyout({ category: CATEGORY })

        await wrapper.events.clear(await wrapper.findByLabelText('Title'))
        await wrapper.events.type(wrapper.getByLabelText('Title'), 'Printers')

        await wrapper.events.click(wrapper.getByRole('button', { name: 'Update' }))

        const calls = await waitForKnowledgeBaseCategoryUpdateMutationCalls()

        expect(calls.at(-1)?.variables).toMatchObject({
          categoryId: CATEGORY.id,
          input: {
            title: 'Printers',
            parentId: PARENT_ID,
          },
          locale: 'en-us',
        })
      })

      // An omitted parent means "leave it where it is" to the mutation, so a move to the
      //   top level only happens if the cleared field goes out as an explicit null.
      it('moves the category to the top level when the parent is cleared', async () => {
        mockParentOptions(42)

        const wrapper = renderFlyout({ category: CATEGORY })

        await wrapper.events.click(await wrapper.findByRole('button', { name: 'Clear selection' }))

        await wrapper.events.click(wrapper.getByRole('button', { name: 'Update' }))

        const calls = await waitForKnowledgeBaseCategoryUpdateMutationCalls()

        expect(calls.at(-1)?.variables.input).toMatchObject({ parentId: null })
      })
    })
  })
})
