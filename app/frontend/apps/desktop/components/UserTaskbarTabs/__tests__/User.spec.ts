// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, h, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { getUserUpdatesSubscriptionHandler } from '#shared/graphql/subscriptions/userUpdates.mocks.ts'
import { EnumTaskbarEntity, type User as UserEntity } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { provideActiveTaskbarTabEntityKey } from '#desktop/composables/useUserTaskbarTab.ts'

import User from '../User/User.vue'

import type { UserTaskbarTab } from '../types.ts'

import '#tests/graphql/builders/mocks.ts'

const TAB_ENTITY_KEY = 'User-2'

const taskbarTab: UserTaskbarTab<UserEntity> = {
  type: EnumTaskbarEntity.UserProfile,
  tabEntityKey: TAB_ENTITY_KEY,
  taskbarTabId: convertToGraphQLId('Taskbar', 1),
  order: 1,
  entity: {
    __typename: 'User',
    id: convertToGraphQLId('User', 2),
    internalId: 2,
    fullname: 'Nicole Braun',
  } as UserEntity,
}

const renderTab = async (activeTaskbarTabEntityKey?: string) => {
  const view = renderComponent(
    defineComponent({
      setup() {
        provideActiveTaskbarTabEntityKey(ref(activeTaskbarTabEntityKey))

        return () => h(User, { taskbarTab, taskbarTabLink: '/users/2' })
      },
    }),
    { router: true, store: true },
  )

  await waitForNextTick()

  return view
}

describe('User taskbar tab', () => {
  it('follows the user updates while the tab has not been opened', async () => {
    const view = await renderTab()

    expect(view.getByText('Nicole Braun')).toBeInTheDocument()
    expect(getUserUpdatesSubscriptionHandler().closed()).toBe(false)
  })

  it('leaves the user updates to the detail view of an opened tab', async () => {
    await renderTab(TAB_ENTITY_KEY)

    expect(getUserUpdatesSubscriptionHandler()).toBeUndefined()
  })
})
