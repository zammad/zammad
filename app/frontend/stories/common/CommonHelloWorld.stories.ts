// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { Story } from '@storybook/vue3'
import CommonHelloWorld from '@common/components/common/CommonHelloWorld.vue'

export default {
  title: 'Common/HelloWorld',
  component: CommonHelloWorld,
  args: {
    show: true,
  },
}

// TODO: Figure out a way to import props definition for components here.
const Template: Story = (args) => ({
  components: { CommonHelloWorld },
  setup() {
    return { args }
  },
  template: '<CommonHelloWorld v-bind="args" />',
})

export const WithoutMessage = Template.bind({})
WithoutMessage.args = {
  msg: '',
}

export const WithMessage = Template.bind({})
WithMessage.args = {
  msg: 'Hello World!!',
}
