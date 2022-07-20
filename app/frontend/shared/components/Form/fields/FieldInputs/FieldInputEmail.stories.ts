// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'

export default {
  title: 'Form/Field/Inputs/Email',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    placeholder: {
      name: 'placeholder',
      type: { name: 'text', required: false },
      desciption: '',
      table: {
        type: { summary: 'text' },
      },
      control: {
        type: 'text',
      },
    },
  },
  parameters: {
    docs: {
      description: {
        component:
          '[FormKit Built-In - Email](https://formkit.com/inputs/email)',
      },
    },
  },
}

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="email" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Email',
  name: 'email',
  placeholder: 'Enter your email address',
}
