// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import CommonAvatar, { type Props } from './CommonAvatar.vue'

export default {
  title: 'Shared/Avatar',
  component: CommonAvatar,
  argTypes: {
    size: {
      control: { type: 'select' },
      options: ['small', 'medium', 'large'],
    },
  },
}

const Template: Story<Props> = (args: Props) => ({
  components: { CommonAvatar },
  setup() {
    return { args }
  },
  template: '<CommonAvatar v-bind="args"/>',
})

const transparentImage = `data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAIAQMAAAD+wSzIAAAABlBMVEX///+/v7+jQ3Y5AAAADklEQVQI12P4AIX8EAgALgAD/aNpbtEAAAAASUVORK5CYII`

export const UserWithImage = Template.bind({})
UserWithImage.args = {
  initials: 'JD',
  image: transparentImage,
}

export const UserVip = Template.bind({})
UserVip.args = {
  initials: 'JD',
  image: transparentImage,
  vip: true,
}

export const UserWithoutImage = Template.bind({})
UserWithoutImage.args = {
  initials: 'JD',
}

export const UserWithIcon = Template.bind({})
UserWithIcon.args = {
  icon: 'facebook',
}

export const UserLarge = Template.bind({})
UserLarge.args = {
  initials: 'JD',
  size: 'large',
  vip: true,
}
