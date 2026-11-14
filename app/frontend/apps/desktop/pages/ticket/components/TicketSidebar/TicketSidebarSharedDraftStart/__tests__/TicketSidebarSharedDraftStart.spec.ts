// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  mockTicketSharedDraftStartListQueryError,
  waitForTicketSharedDraftStartListQueryCalls,
} from '#shared/entities/ticket-shared-draft-start/graphql/queries/ticketSharedDraftStartList.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { TicketSidebarScreenType } from '../../../../types/sidebar.ts'
import sharedDraftStartSidebarPlugin from '../../plugins/shared-draft-start.ts'
import TicketSidebarSharedDraftStart from '../TicketSidebarSharedDraftStart.vue'

import '#tests/graphql/builders/mocks.ts'

mockRouterHooks()

const renderTicketSidebarSharedDraftStart = async (
  context: {
    formValues: Record<string, unknown>
  },
  options: any = {},
) => {
  const result = renderComponent(TicketSidebarSharedDraftStart, {
    props: {
      sidebar: 'shared-draft-start',
      sidebarPlugin: sharedDraftStartSidebarPlugin,
      selected: true,
      context: {
        screenType: TicketSidebarScreenType.TicketCreate,
        ...context,
      },
    },
    router: true,
    form: true,
    global: {
      stubs: {
        teleport: true,
      },
    },
    ...options,
  })

  await waitForNextTick(true)

  return result
}

describe('TicketSidebarSharedDraftStart.vue', () => {
  it('shows sidebar when group ID is present', async () => {
    const wrapper = await renderTicketSidebarSharedDraftStart({
      formValues: {
        group_id: 1,
      },
    })

    expect(wrapper.emitted('show')).toHaveLength(1)
  })

  it('loads the shared drafts of another group when the group changes', async () => {
    const wrapper = await renderTicketSidebarSharedDraftStart({
      formValues: {
        group_id: 1,
      },
    })

    await wrapper.rerender({
      context: {
        screenType: TicketSidebarScreenType.TicketCreate,
        formValues: {
          group_id: 2,
        },
      },
    })

    const calls = await waitForTicketSharedDraftStartListQueryCalls()

    await waitFor(() =>
      expect(calls.at(-1)?.variables).toEqual({ groupId: convertToGraphQLId('Group', 2) }),
    )
  })

  it('does not show sidebar when group ID is absent', async () => {
    // Without a group the backend cannot resolve the list.
    mockTicketSharedDraftStartListQueryError('Group could not be found.', {
      type: GraphQLErrorTypes.UnknownError,
    })

    const wrapper = await renderTicketSidebarSharedDraftStart({
      formValues: {
        group_id: null,
      },
    })

    expect(wrapper.emitted('show')).toBeUndefined()
    expect(wrapper.emitted('hide')).toHaveLength(1)
  })
})
