// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@/stories/support/form/field/defaultArgTypes'

export default {
  title: 'Form/Field/Editor',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
  },
  parameters: {
    docs: {
      description: {
        component: '[Tip Tap](https://tiptap.dev/)',
      },
    },
  },
}

const Template: Story = (args) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="editor" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Body',
  name: 'body',
  value: '<p>Hello World! 🎉</p>',
}
