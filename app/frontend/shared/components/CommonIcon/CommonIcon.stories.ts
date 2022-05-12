// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import ids from 'virtual:svg-icons-names' // eslint-disable-line import/no-unresolved
import type { Story } from '@storybook/vue3'
import CommonIcon, { type Props } from './CommonIcon.vue'

const iconsList = ids.map((item: string) => item.substring(5))

export default {
  title: 'Shared/Icon',
  component: CommonIcon,
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

const Template: Story<Props> = (args: Props) => ({
  components: { CommonIcon },
  setup() {
    return { args }
  },
  template: '<CommonIcon v-bind="args" />',
})

export const BaseIcon = Template.bind({})
BaseIcon.args = {
  name: 'arrow-left',
  size: 'medium',
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

const ListTemplate: Story<Props> = (args: Props) => ({
  components: { CommonIcon },
  setup() {
    return { args, iconsList }
  },
  template:
    '<div class="grid grid-cols-12 max-w-full"><div class="border p-2 items-center align-middle" v-for="iconName in iconsList" :title="iconName"><CommonIcon :name="iconName" v-bind="args" /><span>{{ iconName }}</span></div></div>',
})

export const AllIcons = ListTemplate.bind({})
