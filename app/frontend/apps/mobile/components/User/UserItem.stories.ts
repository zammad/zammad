// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createTemplate from '@stories/support/createTemplate'
import UserItem, { type Props } from './UserItem.vue'

export default {
  title: 'User/UserItem',
  component: UserItem,
}

const Template = createTemplate<Props>(UserItem)

const user = {
  id: '123',
  ticketsCount: 2,
  firstname: 'John',
  lastname: 'Doe',
  organization: {
    name: 'organization',
  },
}

export const Default = Template.create({
  entity: {
    ...user,
    updatedAt: new Date(2022, 1, 2).toISOString(),
    updatedBy: {
      id: '456',
      fullname: 'Jane Doe',
    },
  },
})

export const NoEdit = Template.create({
  entity: user,
})
