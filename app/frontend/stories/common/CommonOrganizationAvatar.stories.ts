// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonOrganizationAvatar, {
  type Props,
} from '@common/components/common/CommonOrganizationAvatar.vue'
import createTemplate from '@stories/support/createTemplate'

export default {
  title: 'Common/OrganizationAvatar',
  component: CommonOrganizationAvatar,
  argTypes: {
    size: {
      control: { type: 'select' },
      options: ['small', 'medium', 'large'],
    },
  },
}

const Template = createTemplate<Props>(CommonOrganizationAvatar)

export const ActiveOrganization = Template.clone()
ActiveOrganization.args = {
  entity: {
    name: 'Active Organization',
    active: true,
  },
}

export const InactiveOrganization = Template.clone()
InactiveOrganization.args = {
  entity: {
    name: 'Inactive Organization',
    active: false,
  },
}
