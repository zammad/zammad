// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import CommonSectionMenu from '@mobile/components/section/CommonSectionMenu.vue'
import CommonSectionMenuLink, {
  type Props,
} from '@mobile/components/section/CommonSectionMenuLink.vue'

export default {
  title: 'section/CommonSectionMenuLink',
  component: CommonSectionMenuLink,
}

const html = String.raw

const Template: Story<Props> = (args: Props) => ({
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
  title: 'Home',
}

export const Action = Template.bind({})
Action.args = {
  title: 'Click Me',
  onClick() {
    // eslint-disable-next-line no-alert
    alert('click')
  },
}
