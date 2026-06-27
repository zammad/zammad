// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'
import { computed } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { SYSTEM_USER_ID, SYSTEM_USER_INTERNAL_ID } from '#shared/utils/constants.ts'

import {
  mockUserInfoForPopoverQuery,
  waitForUserInfoForPopoverQueryCalls,
} from '../UserPopoverWithTrigger/graphql/queries/userInfoForPopover.mocks.ts'
import UserPopover from '../UserPopoverWithTrigger/UserPopover.vue'
import UserPopoverWithTrigger, { type Props } from '../UserPopoverWithTrigger.vue'

const dummyUser = {
  id: convertToGraphQLId('User', 3),
  internalId: 3,
  fullname: 'Nicole Braun',
  vip: false,
  organization: {
    id: convertToGraphQLId('Organization', 1),
    internalId: 1,
    name: 'Zammad Foundation',
    active: true,
    vip: false,
    ticketsCount: {
      open: 5,
      closed: 0,
    },
  },
  secondaryOrganizations: {
    edges: [
      {
        node: {
          id: convertToGraphQLId('Organization', 2),
          internalId: 2,
          active: true,
          vip: false,
          name: 'Apple',
        },
      },
    ],
    totalCount: 1,
  },
  hasSecondaryOrganizations: true,
}

const systemUser = {
  id: SYSTEM_USER_ID,
  internalId: SYSTEM_USER_INTERNAL_ID,
  fullname: 'System',
  vip: false,
  organization: {
    id: convertToGraphQLId('Organization', 1),
    internalId: 1,
    name: 'Zammad Foundation',
    active: true,
    vip: false,
    ticketsCount: {
      open: 5,
      closed: 0,
    },
  },
}

const renderUserPopover = (
  props?: Partial<Props>,
  permission = 'ticket.agent',
  isSystemUser = false,
) => {
  mockUserInfoForPopoverQuery({
    user: props?.user ?? dummyUser,
  })

  mockPermissions([permission])

  return renderComponent(UserPopoverWithTrigger, {
    props: {
      ...props,
      user: isSystemUser ? systemUser : (props?.user ?? dummyUser),
    },
    router: true,
    form: true,
  })
}

describe('UserPopover', () => {
  it('displays the user avatar by default', () => {
    const wrapper = renderUserPopover()
    expect(wrapper.getByRole('img', { name: `Avatar (${dummyUser.fullname})` })).toBeVisible()
  })

  it('shows a skeleton when user info is not available', async () => {
    vi.useFakeTimers()

    vi.spyOn(QueryHandler.prototype, 'loadingWithoutCachedResult').mockReturnValue(
      computed(() => true),
    )

    const wrapper = renderComponent(UserPopover, {
      props: { userAvatar: dummyUser },
      router: true,
      form: true,
    })

    await flushPromises()
    await vi.advanceTimersByTimeAsync(0)

    expect(wrapper.getAllByRole('progressbar')).toHaveLength(10)

    vi.useRealTimers()
    vi.resetAllMocks()
    await vi.dynamicImportSettled()
  })

  it('opens and shows the displays a user popover', async () => {
    const wrapper = renderUserPopover()

    await wrapper.events.hover(wrapper.getByRole('img', { name: `Avatar (${dummyUser.fullname})` }))

    const popover = await wrapper.findByRole('region')
    expect(await within(popover).findByText(dummyUser.fullname)).toBeVisible()

    expect(within(popover).getByText(dummyUser.organization.name)).toBeVisible()
  })

  it('displays secondary organization names', async () => {
    const secondaryOrganizations = {
      edges: [
        {
          node: {
            id: convertToGraphQLId('Organization', 2),
            internalId: 2,
            active: true,
            vip: false,
            name: 'VW',
          },
        },
        {
          node: {
            id: convertToGraphQLId('Organization', 3),
            internalId: 3,
            active: true,
            vip: false,
            name: 'Audi',
          },
        },
        {
          node: {
            id: convertToGraphQLId('Organization', 4),
            internalId: 4,
            active: true,
            vip: false,
            name: 'Apple',
          },
        },
        {
          node: {
            id: convertToGraphQLId('Organization', 5),
            internalId: 5,
            active: true,
            vip: false,
            name: 'Tesla',
          },
        },
      ],
      totalCount: 5,
    }

    const wrapper = renderUserPopover({
      user: {
        ...dummyUser,
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-expect-error
        secondaryOrganizations,
      },
    })

    await wrapper.events.hover(wrapper.getByRole('img', { name: `Avatar (${dummyUser.fullname})` }))

    const calls = await waitForUserInfoForPopoverQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      secondaryOrganizationsCount: 5,
      userId: dummyUser.id,
    })

    const popover = await wrapper.findByRole('region')

    expect(await within(popover).findByText('Apple')).toBeVisible()
  })

  it('renders as link by default', () => {
    const wrapper = renderUserPopover()

    const avatarWrapper = wrapper.getByRole('link')

    expect(avatarWrapper).toHaveAttribute('href', `/users/${dummyUser.internalId}`)
  })

  it('disables link navigation when noTriggerLink is true', () => {
    const wrapper = renderUserPopover({
      noTriggerLink: true,
    })

    const avatarWrapper = wrapper.getByRole('button', {
      name: `Avatar (${dummyUser.fullname})`,
    })

    expect(avatarWrapper).not.toHaveAttribute('href')
  })

  it('applies custom trigger class when provided', () => {
    const customClass = 'custom-trigger-class'
    const wrapper = renderUserPopover({
      triggerClass: customClass,
    })

    const avatarWrapper = wrapper.getByRole('link')

    expect(avatarWrapper).toHaveClass(customClass)
  })

  it('does not display popover for customer user', async () => {
    const wrapper = renderUserPopover(undefined, 'ticket.customer')

    expect(wrapper.queryByRole('link')).not.toBeInTheDocument()

    await wrapper.events.hover(wrapper.getByRole('img', { name: `Avatar (${dummyUser.fullname})` }))

    expect(wrapper.queryByRole('region')).not.toBeInTheDocument()
  })

  it('displays popover for admin user', () => {
    const wrapper = renderUserPopover(undefined, 'admin.user')

    const avatarWrapper = wrapper.getByRole('link')

    expect(avatarWrapper).toHaveAttribute('href', `/users/${dummyUser.internalId}`)
  })

  it('does not display popover for system user', async () => {
    const wrapper = renderUserPopover(undefined, 'ticket.agent', true)

    expect(wrapper.queryByRole('link')).not.toBeInTheDocument()

    await wrapper.events.hover(
      wrapper.getByRole('img', { name: `Avatar (${systemUser.fullname})` }),
    )

    expect(wrapper.queryByRole('region')).not.toBeInTheDocument()
  })
})
