// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'

export default {
  title: 'Form/Field/Inputs/Number',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    value: {
      name: 'value',
      type: { name: 'number', required: false },
      description: '',
      table: {
        type: { summary: 'number' },
      },
      control: {
        type: 'number',
      },
    },
    min: {
      name: 'min',
      type: { name: 'number', required: false },
      desciption: '',
      table: {
        type: { summary: 'number' },
      },
      control: {
        type: 'number',
      },
    },
    max: {
      name: 'max',
      type: { name: 'number', required: false },
      desciption: '',
      table: {
        type: { summary: 'number' },
      },
      control: {
        type: 'number',
      },
    },
    step: {
      name: 'step',
      type: { name: 'number', required: false },
      desciption: '',
      table: {
        type: { summary: 'number' },
        defaultValue: {
          summary: 'auto',
        },
      },
      control: {
        type: 'number',
      },
    },
  },
  parameters: {
    docs: {
      description: {
        component:
          '[FormKit Built-In - Number](https://formkit.com/inputs/number)',
      },
    },
  },
}

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="number" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Number',
  name: 'number',
}
