// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import CommonSectionMenu from './CommonSectionMenu.vue'
import CommonSectionMenuLink, { type Props } from './CommonSectionMenuLink.vue'

export default {
  title: 'Apps/Mobile/CommonSectionMenu/CommonSectionMenuLink',
  component: CommonSectionMenuLink,
}

const html = String.raw

interface Actions {
  onClick(): void
}

const Template: Story<Props & Actions> = (args: Props & Actions) => ({
  components: { CommonSectionMenuLink, CommonSectionMenu },
  setup() {
    return { args }
  },
  template: html`
    <CommonSectionMenu>
      <CommonSectionMenuLink v-bind="args" />
    </CommonSectionMenu>
  `,
})

export const Default = Template.bind({})
Default.args = {
  link: '/',
  icon: 'home',
  information: '33',
  label: 'Home',
}

export const Action = Template.bind({})
Action.args = {
  label: 'Click Me',
  onClick() {
    // eslint-disable-next-line no-alert
    alert('click')
  },
}
