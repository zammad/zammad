// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@/stories/support/form/field/defaultArgTypes'

export default {
  title: 'Form/Field/Inputs/Date',
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
        type: 'date',
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
        component: '[FormKit Built-In - Date](https://formkit.com/inputs/date)',
      },
    },
  },
}

const Template: Story = (args) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="date" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Date',
  name: 'date',
}
