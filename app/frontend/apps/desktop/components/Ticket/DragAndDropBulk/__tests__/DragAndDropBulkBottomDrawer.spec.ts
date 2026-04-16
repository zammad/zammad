// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { fireEvent } from '@testing-library/vue'
import { nextTick } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import '#tests/graphql/builders/mocks.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import DragAndDropBulkBottomDrawer from '../DragAndDropBulkBottomDrawer.vue'

const defaultProps = {
  isActive: false,
  ticketIds: new Set(['1', '2']),
  groupIds: [] as string[],
  bulkContext: { overviewId: convertToGraphQLId('Overview', '1') },
  bulkCount: 5,
}

describe('DragAndDropBulkBottomDrawer', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: { options: [] },
          owner_id: { options: [] },
        },
      },
    })
  })

  const renderDrawer = (props: Partial<typeof defaultProps> = {}) =>
    renderComponent(DragAndDropBulkBottomDrawer, {
      props: { ...defaultProps, ...props },
      router: true,
    })

  describe('loading state', () => {
    it('shows skeleton while query is loading', () => {
      const wrapper = renderDrawer()

      expect(wrapper.getByRole('progressbar', { name: 'Content loader' })).toBeInTheDocument()
    })
  })

  describe('inactive state', () => {
    it('shows "Assign tickets" circle card when groups are available', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: { options: [{ value: 1, label: 'Support', disabled: false }] },
            owner_id: { options: [] },
          },
        },
      })

      const wrapper = renderDrawer()

      await waitForFormUpdaterQueryCalls()

      expect(await wrapper.findByText('Assign tickets')).toBeVisible()
    })

    it('shows the full list view with "Assign tickets" heading when no groups are available', async () => {
      const wrapper = renderDrawer()

      await waitForFormUpdaterQueryCalls()

      expect(await wrapper.findByText('Assign tickets')).toBeVisible()
    })
  })

  describe('active state', () => {
    it('always shows "Unassign owner" option', async () => {
      const wrapper = renderDrawer({ isActive: true })

      await waitForFormUpdaterQueryCalls()

      expect(await wrapper.findByText('Unassign owner')).toBeVisible()
    })

    it('shows owner items from the form updater response', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: { options: [] },
            owner_id: {
              options: [
                { value: 42, label: 'John Doe', object: { id: convertToGraphQLId('User', '42') } },
              ],
            },
          },
        },
      })

      const wrapper = renderDrawer({ isActive: true })

      await waitForFormUpdaterQueryCalls()

      expect(await wrapper.findByText('John Doe')).toBeVisible()
    })

    it('shows group items from the form updater response', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: { options: [{ value: 1, label: 'Support', disabled: false }] },
            owner_id: { options: [] },
          },
        },
      })

      const wrapper = renderDrawer({ isActive: true })

      await waitForFormUpdaterQueryCalls()

      expect(await wrapper.findByText('Support')).toBeVisible()
    })

    it('shows parent group label as breadcrumb for nested groups', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 1,
                  label: 'Support',
                  disabled: false,
                  children: [{ value: 2, label: 'Level 2', disabled: false }],
                },
              ],
            },
            owner_id: { options: [] },
          },
        },
      })

      const wrapper = renderDrawer({ isActive: true })

      await waitForFormUpdaterQueryCalls()

      expect(await wrapper.findAllByText('Support')).toHaveLength(1)
      expect(wrapper.getByText('Level 2')).toBeVisible()
    })
  })

  describe('inside group state', () => {
    it('shows group members, "Users" heading, and "Go back" button after hovering go-inside-group', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: { options: [{ value: 1, label: 'Support', disabled: false }] },
            owner_id: {
              options: [
                { value: 42, label: 'John Doe', object: { id: convertToGraphQLId('User', '42') } },
              ],
            },
          },
        },
      })

      vi.useFakeTimers()

      const wrapper = renderDrawer({ isActive: true })

      expect(await wrapper.findByText('Support')).toBeVisible()

      try {
        const insideGroupArea = wrapper.getByIconName('arrow-down-short').parentElement!
        await fireEvent.mouseEnter(insideGroupArea)
        await vi.runAllTimersAsync()
        await nextTick()

        expect(wrapper.getByText('Support')).toBeInTheDocument()
        expect(wrapper.getByText('John Doe')).toBeInTheDocument()
        expect(wrapper.getByIconName('arrow-up-short').closest('button')).toBeInTheDocument()
      } finally {
        vi.useRealTimers()
      }
    })

    it('shows unassign owner option inside group', async () => {
      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: { options: [{ value: 1, label: 'Support', disabled: false }] },
            owner_id: {
              options: [
                { value: 42, label: 'John Doe', object: { id: convertToGraphQLId('User', '42') } },
              ],
            },
          },
        },
      })

      const wrapper = renderDrawer({ isActive: true })

      expect(await wrapper.findByText('Support')).toBeVisible()

      expect(wrapper.queryByText('Unassign owner')).toBeVisible()
    })
  })
})
