// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createTemplate from '@stories/support/createTemplate'
import OrganizationItem, { type Props } from './OrganizationItem.vue'

export default {
  title: 'Organization/OrganizationItem',
  component: OrganizationItem,
}

const Template = createTemplate<Props>(OrganizationItem)

const organization = {
  id: '54321',
  internalId: 2,
  ticketsCount: 2,
  name: 'Lorem Ipsum',
  active: false,
}

export const Default = Template.create({
  entity: {
    ...organization,
    active: true,
    updatedAt: new Date(2022, 1, 2).toISOString(),
    updatedBy: {
      id: '456',
      fullname: 'Jane Doe',
    },
    members: {
      edges: [
        {
          node: { fullname: 'Erik Wise' },
        },
        {
          node: { fullname: 'Peter Smith' },
        },
      ],
      totalCount: 3,
    },
  },
})

export const NoEdit = Template.create({
  entity: organization,
})
