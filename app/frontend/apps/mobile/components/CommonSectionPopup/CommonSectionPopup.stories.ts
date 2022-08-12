// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { ref } from 'vue'
import CommonSectionPopup, { type Props } from './CommonSectionPopup.vue'

export default {
  title: 'Apps/Mobile/CommonSectionPopup',
  component: CommonSectionPopup,
}

const html = String.raw

const Template: Story<Props> = (args: Props) => ({
  components: { CommonSectionPopup },
  setup() {
    const state = ref(args.state)
    return { args, state }
  },
  template: html`
    <button @click="state = true">Open Popup</button>
    <CommonSectionPopup v-bind="args" v-model:state="state" />
  `,
})

export const Default = Template.bind({})

Default.args = {
  items: [
    {
      label: 'Some Item',
      onAction() {
        // eslint-disable-next-line no-alert
        alert('clicked!')
      },
    },
  ],
  state: false,
}
