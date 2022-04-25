// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonUserAvatar, {
  type Props,
} from '@common/components/common/CommonUserAvatar.vue'
import createTemplate from '@stories/support/createTemplate'

export default {
  title: 'Common/UserAvatar',
  component: CommonUserAvatar,
  argTypes: {
    size: {
      control: { type: 'select' },
      options: ['small', 'medium', 'large'],
    },
  },
}

const Template = createTemplate<Props>(CommonUserAvatar)

export const SystemUser = Template.clone()
SystemUser.args = {
  entity: {
    id: '1',
  },
}

export const UserWithoutIcon = Template.clone()
UserWithoutIcon.args = {
  entity: {
    id: '2',
    firstname: 'John',
    lastname: 'Doe',
  },
}

export const FacebookUser = Template.clone()
FacebookUser.args = {
  entity: {
    id: '2',
    source: 'facebook',
  },
}

export const VipUser = Template.clone()
VipUser.args = {
  entity: {
    id: '2',
    vip: true,
    email: 'jd@email.com',
  },
  personal: false,
}

export const InactiveUser = Template.clone()
InactiveUser.args = {
  entity: {
    id: '2',
    active: false,
    firstname: 'John',
    lastname: 'Doe',
  },
}

export const UserOnVacation = Template.clone()
UserOnVacation.args = {
  entity: {
    id: '2',
    outOfOffice: true,
    firstname: 'John',
    lastname: 'Doe',
  },
}
