// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import CommonButtonGroup, { type Props } from './CommonButtonGroup.vue'

export default {
  title: 'Apps/Mobile/CommonButtonGroup',
  component: CommonButtonGroup,
}

const Template: Story<Props> = (args) => ({
  components: { CommonButtonGroup },
  setup() {
    return { args }
  },
  template: '<CommonButtonGroup v-bind="args"/>',
})

const onAction = () => {
  // eslint-disable-next-line no-alert
  window.alert('clicked!')
}

export const Default = Template.bind({})
Default.args = {
  options: [
    { label: 'link %s', labelPlaceholder: ['text'], link: '/example' },
    { label: 'button', onAction, selected: true },
    { label: 'with-icon', onAction, icon: 'home', disabled: true },
  ],
}
