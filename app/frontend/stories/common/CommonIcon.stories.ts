// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Story } from '@storybook/vue3'
import CommonIcon from '@common/components/common/CommonIcon.vue'
import ids from 'virtual:svg-icons-names' // eslint-disable-line import/no-unresolved

const iconsList = ids.map((item) => item.substring(5))

export default {
  title: 'Common/Icon',
  component: CommonIcon,
  args: {
    name: '',
    size: 'medium',
    fixedSize: null,
    decorative: false,
    animation: '',
  },
  argTypes: {
    name: {
      control: { type: 'select' },
      options: iconsList,
    },
    size: {
      control: { type: 'select' },
      options: ['small', 'medium', 'large'],
    },
    animation: {
      control: { type: 'select' },
      options: ['pulse', 'spin', 'ping', 'bounce'],
    },
  },
}

const Template: Story = (args) => ({
  components: { CommonIcon },
  setup() {
    return { args }
  },
  template: '<CommonIcon v-bind="args" />',
})

export const BaseIcon = Template.bind({})
BaseIcon.args = {
  name: 'arrow-left',
}

export const BaseIconAnimated = Template.bind({})
BaseIconAnimated.args = {
  name: 'cog',
  animation: 'spin',
}

export const BaseIconDecorative = Template.bind({})
BaseIconDecorative.args = {
  name: 'dashboard',
  decorative: true,
}
