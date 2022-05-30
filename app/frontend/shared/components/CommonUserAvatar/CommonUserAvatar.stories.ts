// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createTemplate from '@stories/support/createTemplate'
import CommonUserAvatar, { type Props } from './CommonUserAvatar.vue'

export default {
  title: 'Shared/UserAvatar',
  component: CommonUserAvatar,
  argTypes: {
    size: {
      control: { type: 'select' },
      options: ['small', 'medium', 'large'],
    },
  },
}

const Template = createTemplate<Props>(CommonUserAvatar)

export const SystemUser = Template.create({
  entity: {
    id: '1',
  },
})

export const UserWithoutIcon = Template.create({
  entity: {
    id: '2',
    firstname: 'John',
    lastname: 'Doe',
  },
})

export const FacebookUser = Template.create({
  entity: {
    id: '2',
    source: 'facebook',
  },
})

export const VipUser = Template.create({
  entity: {
    id: '2',
    vip: true,
    email: 'jd@email.com',
  },
  personal: false,
})

export const InactiveUser = Template.create({
  entity: {
    id: '2',
    active: false,
    firstname: 'John',
    lastname: 'Doe',
  },
})

export const UserOnVacation = Template.create({
  entity: {
    id: '2',
    outOfOffice: true,
    firstname: 'John',
    lastname: 'Doe',
  },
})
