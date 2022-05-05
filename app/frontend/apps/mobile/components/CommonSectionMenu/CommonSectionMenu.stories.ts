// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import CommonSectionMenu, {
  type Props,
} from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'

export default {
  title: 'Apps/Mobile/CommonSectionMenu/CommonSectionMenu',
  component: CommonSectionMenu,
}

const Template: Story<Props> = (args: Props) => ({
  components: { CommonSectionMenu },
  setup() {
    return { args }
  },
  template: '<CommonSectionMenu v-bind="args"/> ',
})

export const Default = Template.bind({})
Default.args = {
  items: [
    {
      type: 'link',
      link: '/',
      icon: 'home',
      title: 'Home',
    },
    {
      type: 'link',
      title: 'Action',
      onClick() {
        // eslint-disable-next-line no-alert
        alert('click')
      },
    },
  ],
}

export const Action = Template.bind({})
Action.args = {
  headerTitle: 'Header',
  actionTitle: 'Click Me',
  onActionClick() {
    // eslint-disable-next-line no-alert
    alert('action clicked')
  },
  items: [
    {
      type: 'link',
      link: '/',
      icon: 'home',
      title: 'Home',
    },
  ],
}
