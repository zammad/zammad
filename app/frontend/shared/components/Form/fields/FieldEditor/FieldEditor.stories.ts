// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'

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

const html = String.raw

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: html`<div class="relative h-[200px] bg-black text-white">
    <FormKit type="editor" v-bind="args" />
  </div>`,
})

export const Default = Template.bind({})
Default.args = {
  label: 'Click text',
  name: 'body',
  value: '<p>Hello <b>World</b>! 🎉</p>',
}
