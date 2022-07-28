// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import CommonLink, { type Props } from './CommonLink.vue'

export default {
  title: 'Shared/Link',
  component: CommonLink,
}

const Template: Story<Props> = (args: Props) => ({
  components: { CommonLink },
  setup() {
    return { args }
  },
  template: '<CommonLink v-bind="args">A test Link</CommonLink>',
})

export const BasicLink = Template.bind({})
BasicLink.args = {
  link: 'https://www.google.com',
}

export const ExternalLink = Template.bind({})
ExternalLink.args = {
  link: 'https://www.google.com',
  external: true,
  openInNewTab: true,
}

export const RouterLink = Template.bind({})
RouterLink.args = {
  link: '/login',
  internal: true,
}

export const DisabledLink = Template.bind({})
DisabledLink.args = {
  link: '/login',
  disabled: true,
}
