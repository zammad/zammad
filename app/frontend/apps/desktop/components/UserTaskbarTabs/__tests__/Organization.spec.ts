// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, h, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { getOrganizationUpdatesSubscriptionHandler } from '#shared/entities/organization/graphql/subscriptions/organizationUpdates.mocks.ts'
import {
  EnumTaskbarEntity,
  type Organization as OrganizationEntity,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { provideActiveTaskbarTabEntityKey } from '#desktop/composables/useUserTaskbarTab.ts'

import Organization from '../Organization/Organization.vue'

import type { UserTaskbarTab } from '../types.ts'

import '#tests/graphql/builders/mocks.ts'

const TAB_ENTITY_KEY = 'Organization-3'

const taskbarTab: UserTaskbarTab<OrganizationEntity> = {
  type: EnumTaskbarEntity.OrganizationProfile,
  tabEntityKey: TAB_ENTITY_KEY,
  taskbarTabId: convertToGraphQLId('Taskbar', 1),
  order: 1,
  entity: {
    __typename: 'Organization',
    id: convertToGraphQLId('Organization', 3),
    internalId: 3,
    name: 'Zammad Foundation',
  } as OrganizationEntity,
}

const renderTab = async (activeTaskbarTabEntityKey?: string) => {
  const view = renderComponent(
    defineComponent({
      setup() {
        provideActiveTaskbarTabEntityKey(ref(activeTaskbarTabEntityKey))

        return () => h(Organization, { taskbarTab, taskbarTabLink: '/organizations/3' })
      },
    }),
    { router: true, store: true },
  )

  await waitForNextTick()

  return view
}

describe('Organization taskbar tab', () => {
  it('follows the organization updates while the tab has not been opened', async () => {
    const view = await renderTab()

    expect(view.getByText('Zammad Foundation')).toBeInTheDocument()
    expect(getOrganizationUpdatesSubscriptionHandler().closed()).toBe(false)
  })

  it('leaves the organization updates to the detail view of an opened tab', async () => {
    await renderTab(TAB_ENTITY_KEY)

    expect(getOrganizationUpdatesSubscriptionHandler()).toBeUndefined()
  })
})
