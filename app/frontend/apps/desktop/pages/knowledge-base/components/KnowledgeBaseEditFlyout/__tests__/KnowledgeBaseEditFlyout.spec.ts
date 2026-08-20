// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { within } from '@testing-library/vue'

import renderComponent, { initializePiniaStore } from '#tests/support/components/renderComponent.ts'

import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockKnowledgeBaseUpdateMutation,
  waitForKnowledgeBaseUpdateMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseUpdate.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'

import KnowledgeBaseEditFlyout from '../KnowledgeBaseEditFlyout.vue'

const FLYOUT_NAME = 'knowledge-base-edit'

const KNOWLEDGE_BASE_ID = convertToGraphQLId('KnowledgeBase', 1)
const KB_LOCALE_ID = convertToGraphQLId('KnowledgeBase::Locale', 1)

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
      inheritedAccess: null,
      allowedAccesses: ['reader', 'none'],
    },
  ],
  initialValue: { 1: 'editor', 2: 'reader' },
}

const mockKnowledgeBase = () => {
  mockKnowledgeBaseQuery({
    knowledgeBase: {
      id: KNOWLEDGE_BASE_ID,
      title: 'Support Center',
      footerNote: 'Friendly footer',
      iconset: 'FontAwesome',
      isPubliclyAvailable: true,
      isVisiblePublicly: true,
      policy: { update: true },
      kbLocales: [
        {
          id: KB_LOCALE_ID,
          primary: true,
          systemLocale: { id: '1', locale: 'en-us', name: 'English (United States)' },
        },
      ],
      currentLocale: {
        id: KB_LOCALE_ID,
        systemLocale: { id: '1', locale: 'en-us' },
      },
    },
  })
}

const mockUpdater = (options: { permissions?: boolean } = { permissions: true }) => {
  mockFormUpdaterQuery({
    formUpdater: {
      fields: options.permissions ? { permissions: PERMISSIONS_FIELD } : {},
    },
  })
}

const renderFlyout = () => {
  initializePiniaStore()
  mockKnowledgeBase()

  return renderComponent(KnowledgeBaseEditFlyout, {
    props: {
      name: FLYOUT_NAME,
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

describe('KnowledgeBaseEditFlyout', () => {
  it('renders only the root fields with the stored values', async () => {
    mockUpdater()

    const wrapper = renderFlyout()

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent('Edit knowledge base')

    expect(await wrapper.findByLabelText('Title')).toHaveValue('Support Center')
    expect(wrapper.getByLabelText('Footer note')).toHaveValue('Friendly footer')
    expect(wrapper.queryByLabelText('Icon')).not.toBeInTheDocument()
    expect(wrapper.queryByLabelText('Parent category')).not.toBeInTheDocument()
  })

  it('identifies the knowledge base to the form updater', async () => {
    mockUpdater()

    renderFlyout()

    const calls = await waitForFormUpdaterQueryCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      id: KNOWLEDGE_BASE_ID,
      meta: { initial: true },
    })
  })

  describe('permissions matrix', () => {
    it('renders a row per role with the resolved access preselected', async () => {
      mockUpdater()

      const wrapper = renderFlyout()

      const table = within(await wrapper.findByRole('table'))

      expect(table.getAllByRole('row')).toHaveLength(3)
      expect(wrapper.getByLabelText('Admin - Editor')).toBeChecked()
      expect(wrapper.getByLabelText('Agent - Reader')).toBeChecked()
    })

    it('lets an access be picked', async () => {
      mockUpdater()

      const wrapper = renderFlyout()

      await wrapper.events.click(await wrapper.findByLabelText('Agent - None'))

      expect(wrapper.getByLabelText('Agent - None')).toBeChecked()
      expect(wrapper.getByLabelText('Agent - Reader')).not.toBeChecked()
    })

    it('stays hidden when the form updater does not resolve it', async () => {
      mockUpdater({ permissions: false })

      const wrapper = renderFlyout()

      expect(await wrapper.findByLabelText('Title')).toBeInTheDocument()
      expect(wrapper.queryByRole('table')).not.toBeInTheDocument()
    })
  })

  describe('saving', () => {
    it('updates the knowledge base in the browsed locale', async () => {
      mockUpdater()

      const wrapper = renderFlyout()

      await wrapper.events.clear(await wrapper.findByLabelText('Title'))
      await wrapper.events.type(wrapper.getByLabelText('Title'), 'Help Center')
      await wrapper.events.clear(wrapper.getByLabelText('Footer note'))
      await wrapper.events.type(wrapper.getByLabelText('Footer note'), 'Updated footer')
      await wrapper.events.click(wrapper.getByRole('button', { name: 'Update' }))

      const calls = await waitForKnowledgeBaseUpdateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: {
          title: 'Help Center',
          footerNote: 'Updated footer',
          permissions: [
            { roleId: convertToGraphQLId('Role', 1), access: 'editor' },
            { roleId: convertToGraphQLId('Role', 2), access: 'reader' },
          ],
        },
        // The locale of the call: the texts are written into it and come back in it.
        locale: 'en-us',
      })
    })

    it('says nothing about permissions when the matrix never appeared', async () => {
      mockUpdater({ permissions: false })

      const wrapper = renderFlyout()

      // The footer button exists before the form does: submitting has to wait for the form to be
      //   there with its values, or the click lands on nothing and no mutation is ever sent.
      expect(await wrapper.findByLabelText('Title')).toHaveValue('Support Center')
      await waitForFormUpdaterQueryCalls()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Update' }))

      const calls = await waitForKnowledgeBaseUpdateMutationCalls()

      expect(calls.at(-1)?.variables.input).not.toHaveProperty('permissions')
    })

    // The backend reports a title error on the knowledge base's translation, so without
    //   remapping it the message would land on the form rather than on the field.
    it('shows a title error on the title field', async () => {
      mockUpdater()

      mockKnowledgeBaseUpdateMutation({
        knowledgeBaseUpdate: {
          knowledgeBase: null,
          errors: [
            { message: 'is too long (maximum is 250 characters)', field: 'translations.title' },
          ],
        },
      })

      const wrapper = renderFlyout()

      expect(await wrapper.findByLabelText('Title')).toHaveValue('Support Center')
      await wrapper.events.click(wrapper.getByRole('button', { name: 'Update' }))

      expect(
        await wrapper.findByText('is too long (maximum is 250 characters)'),
      ).toBeInTheDocument()

      // On the field itself, and not additionally on the form root — which is where a field
      //   name that cannot be resolved to a field ends up instead.
      const formNode = getNode('form-knowledge-base')!
      expect(formNode.find('title', 'name')?.context?.state.errors).toBe(true)
      expect(Object.values(formNode.store).filter((message) => message.type === 'error')).toEqual(
        [],
      )

      // Still on the form, so the failed title can be corrected.
      expect(wrapper.getByLabelText('Title')).toHaveValue('Support Center')
    })

    // A refused permission matrix is named after the matrix, so it has to show up there rather
    //   than as a form-level message detached from the table the user has to fix.
    it('shows a permissions error on the matrix', async () => {
      mockUpdater()

      mockKnowledgeBaseUpdateMutation({
        knowledgeBaseUpdate: {
          knowledgeBase: null,
          errors: [
            {
              message: 'These permissions are invalid because they would lock you out.',
              field: 'permissions',
            },
          ],
        },
      })

      const wrapper = renderFlyout()

      await wrapper.events.click(await wrapper.findByLabelText('Agent - None'))
      await wrapper.events.click(wrapper.getByRole('button', { name: 'Update' }))

      expect(
        await wrapper.findByText('These permissions are invalid because they would lock you out.'),
      ).toBeInTheDocument()

      const formNode = getNode('form-knowledge-base')!

      expect(formNode.find('permissions', 'name')?.context?.state.errors).toBe(true)
      expect(Object.values(formNode.store).filter((message) => message.type === 'error')).toEqual(
        [],
      )
    })
  })
})
