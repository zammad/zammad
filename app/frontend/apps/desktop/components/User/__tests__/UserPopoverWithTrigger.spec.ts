// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  mockUserQuery,
  waitForUserQueryCalls,
} from '#shared/entities/user/graphql/queries/user.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import {
  SYSTEM_USER_ID,
  SYSTEM_USER_INTERNAL_ID,
} from '#shared/utils/constants.ts'

import UserPopoverWithTrigger, {
  type Props,
} from '#desktop/components/User/UserPopoverWithTrigger.vue'

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
  isAgent = true,
  isSystemUser = false,
) => {
  mockUserQuery({
    user: props?.user ?? dummyUser,
  })

  mockPermissions([isAgent ? 'ticket.agent' : 'ticket.customer'])

  return renderComponent(UserPopoverWithTrigger, {
    props: {
      ...props,
      user: isSystemUser ? systemUser : (props?.user ?? dummyUser),
    },
    router: true,
  })
}

describe('UserPopover', () => {
  it('displays the user avatar by default', () => {
    const wrapper = renderUserPopover()
    expect(
      wrapper.getByRole('img', { name: `Avatar (${dummyUser.fullname})` }),
    ).toBeVisible()
  })

  it('shows a skeleton when user info is not available', async () => {
    const wrapper = renderUserPopover()

    await wrapper.events.hover(
      wrapper.getByRole('img', { name: `Avatar (${dummyUser.fullname})` }),
    )

    const popover = await wrapper.findByRole('region')
    // :TODO a11y testing
    expect(within(popover).getAllByRole('progressbar').length).toBe(10)
  })

  it('opens and shows the displays a user popover', async () => {
    const wrapper = renderUserPopover()

    await wrapper.events.hover(
      wrapper.getByRole('img', { name: `Avatar (${dummyUser.fullname})` }),
    )

    const popover = await wrapper.findByRole('region')
    expect(await within(popover).findByText(dummyUser.fullname)).toBeVisible()

    expect(within(popover).getByText(dummyUser.organization.name)).toBeVisible()
  })

  it.todo('displays organization names with remaining count', async () => {
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
      ],
      totalCount: 4,
    }

    mockUserQuery({
      user: {
        ...dummyUser,
        secondaryOrganizations,
      },
    })

    const wrapper = renderUserPopover()

    await wrapper.events.hover(
      wrapper.getByRole('img', { name: `Avatar (${dummyUser.fullname})` }),
    )

    await waitForUserQueryCalls()

    const popover = await wrapper.findByRole('region')

    expect(await within(popover).findByText('VW')).toBeVisible()
    expect(within(popover).getByText('Audi')).toBeVisible()
    expect(within(popover).getByText('Apple')).toBeVisible()

    expect(within(popover).getByRole('link', { name: '1 more' })).toBeVisible()
  })

  it('renders as link by default', () => {
    const wrapper = renderUserPopover()

    const avatarWrapper = wrapper.getByRole('link')

    expect(avatarWrapper).toHaveAttribute(
      'href',
      `/user/profile/${dummyUser.internalId}`,
    )
  })

  it('disables link navigation when noLink is true', () => {
    const wrapper = renderUserPopover({
      noLink: true,
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
    const wrapper = renderUserPopover(undefined, false)

    expect(wrapper.queryByRole('link')).not.toBeInTheDocument()

    await wrapper.events.hover(
      wrapper.getByRole('img', { name: `Avatar (${dummyUser.fullname})` }),
    )

    expect(wrapper.queryByRole('region')).not.toBeInTheDocument()
  })

  it('does not display popover for system user', async () => {
    const wrapper = renderUserPopover(undefined, true, true)

    expect(wrapper.queryByRole('link')).not.toBeInTheDocument()

    await wrapper.events.hover(
      wrapper.getByRole('img', { name: `Avatar (${systemUser.fullname})` }),
    )

    expect(wrapper.queryByRole('region')).not.toBeInTheDocument()
  })
})
