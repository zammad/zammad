// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import createTemplate from '@stories/support/createTemplate'
import CommonOrganizationAvatar, {
  type Props,
} from './CommonOrganizationAvatar.vue'

export default {
  title: 'Shared/OrganizationAvatar',
  component: CommonOrganizationAvatar,
  argTypes: {
    size: {
      control: { type: 'select' },
      options: ['small', 'medium', 'large'],
    },
  },
}

const Template = createTemplate<Props>(CommonOrganizationAvatar)

export const ActiveOrganization = Template.create()
ActiveOrganization.args = {
  entity: {
    name: 'Active Organization',
    active: true,
  },
}

export const InactiveOrganization = Template.create()
InactiveOrganization.args = {
  entity: {
    name: 'Inactive Organization',
    active: false,
  },
}
