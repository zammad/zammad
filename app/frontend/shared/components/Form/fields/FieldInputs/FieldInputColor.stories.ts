// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'

export default {
  title: 'Form/Field/Inputs/Color',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    value: {
      name: 'value',
      type: { name: 'string', required: false },
      description: '',
      table: {
        type: { summary: 'string' },
      },
      control: {
        type: 'color',
      },
    },
  },
  parameters: {
    docs: {
      description: {
        component:
          '[FormKit Built-In - Color](https://formkit.com/inputs/color)',
      },
    },
  },
}

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="color" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Color',
  name: 'color',
}
