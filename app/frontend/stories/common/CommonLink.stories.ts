// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonLink from '@common/components/common/CommonLink.vue'
import { Story } from '@storybook/vue3'

export default {
  title: 'Common/Link',
  component: CommonLink,
  args: {
    link: '',
    isExternal: false,
    isRoute: false,
    disabled: false,
    rel: '',
    target: '',
    openInNewTab: false,
    replace: false,
    activeClass: '',
    exactActiveClass: '',
  },
  parameters: {
    actions: {
      handles: ['click'],
    },
  },
}

const Template: Story = (args) => ({
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
  isExternal: true,
  openInNewTab: true,
}

export const RouterLink = Template.bind({})
RouterLink.args = {
  link: '/login',
  isRoute: true,
}

export const DisabledLink = Template.bind({})
DisabledLink.args = {
  link: '/login',
  disabled: true,
}
