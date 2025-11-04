// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockOrganizationInfoForPopoverQuery } from '../OrganizationPopoverWithTrigger/graphql/queries/organizationInfoForPopover.mocks.ts'
import OrganizationPopoverWithTrigger, { type Props } from '../OrganizationPopoverWithTrigger.vue'

const dummyOrganization = {
  id: convertToGraphQLId('Organization', 1),
  internalId: 1,
  name: 'Zammad Foundation',
  vip: false,
  allMembers: {
    edges: [
      {
        node: {
          id: convertToGraphQLId('User', 1),
          internalId: 1,
          fullname: 'Nicole Braun',
          vip: false,
        },
      },
    ],
    totalCount: 1,
  },
  active: true,
}

const renderOrganizationPopover = (props?: Partial<Props>, isAgent = true) => {
  mockOrganizationInfoForPopoverQuery({
    organization: props?.organization ?? dummyOrganization,
  })

  mockPermissions([isAgent ? 'ticket.agent' : 'ticket.customer'])

  return renderComponent(OrganizationPopoverWithTrigger, {
    props: {
      ...props,
      organization: props?.organization ?? dummyOrganization,
    },
    router: true,
  })
}

describe('OrganizationPopover', () => {
  it('displays the organization avatar by default', () => {
    const wrapper = renderOrganizationPopover()
    expect(wrapper.getByRole('img', { name: `Avatar (${dummyOrganization.name})` })).toBeVisible()
  })

  it('shows a skeleton when user info is not available', async () => {
    const wrapper = renderOrganizationPopover()

    await wrapper.events.hover(
      wrapper.getByRole('img', { name: `Avatar (${dummyOrganization.name})` }),
    )

    const popover = await wrapper.findByRole('region')
    // :TODO a11y testing
    expect(within(popover).getAllByRole('progressbar').length).toBe(10)
  })

  it('displays the organization popover on hover', async () => {
    const wrapper = renderOrganizationPopover()

    await wrapper.events.hover(
      wrapper.getByRole('img', { name: `Avatar (${dummyOrganization.name})` }),
    )

    const popover = await wrapper.findByRole('region')

    expect(await within(popover).findByText(dummyOrganization.name)).toBeVisible()

    expect(
      await within(popover).findByText(dummyOrganization.allMembers.edges[0].node.fullname),
    ).toBeVisible()
  })

  it('renders as link by default', () => {
    const wrapper = renderOrganizationPopover()

    const avatarWrapper = wrapper.getByRole('link')

    expect(avatarWrapper).toHaveAttribute(
      'href',
      `/organization/profile/${dummyOrganization.internalId}`,
    )
  })

  it('disables link navigation when noLink is true', () => {
    const wrapper = renderOrganizationPopover({
      noLink: true,
    })

    const avatarWrapper = wrapper.getByRole('button', {
      name: `Avatar (${dummyOrganization.name})`,
    })

    expect(avatarWrapper).not.toHaveAttribute('href')
  })

  it('applies custom trigger class when provided', () => {
    const customClass = 'custom-trigger-class'

    const wrapper = renderOrganizationPopover({
      triggerClass: customClass,
    })

    const avatarWrapper = wrapper.getByRole('link')

    expect(avatarWrapper).toHaveClass(customClass)
  })

  it('does not display popover for customer user', async () => {
    const wrapper = renderOrganizationPopover(undefined, false)

    expect(wrapper.queryByRole('link')).not.toBeInTheDocument()

    await wrapper.events.hover(
      wrapper.getByRole('img', { name: `Avatar (${dummyOrganization.name})` }),
    )

    expect(wrapper.queryByRole('region')).not.toBeInTheDocument()
  })
})
