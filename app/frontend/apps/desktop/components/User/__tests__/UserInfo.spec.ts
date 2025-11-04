// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import UserInfo from '#desktop/components/User/UserInfo.vue'

describe('UserInfo', () => {
  it('displays the user info correctly', () => {
    const user = generateObjectData('User', {
      id: convertToGraphQLId('User', 2),
      internalId: 2,
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
    })

    const wrapper = renderComponent(UserInfo, {
      props: {
        user,
      },
      router: true,
    })

    expect(wrapper.getByText(user.fullname)).toBeVisible()

    expect(wrapper.getByRole('img', { name: `Avatar (${user.fullname})` })).toBeVisible()

    expect(wrapper.getByRole('link', { name: user.organization.name })).toHaveAttribute(
      'href',
      `/organization/profile/${user.organization.internalId}`,
    )
  })
})
