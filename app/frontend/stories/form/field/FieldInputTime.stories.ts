// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@/stories/support/form/field/defaultArgTypes'

export default {
  title: 'Form/Field/Inputs/Time',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
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
        component: '[FormKit Built-In - Time](https://formkit.com/inputs/time)',
      },
    },
  },
}

const Template: Story = (args) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="time" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Time',
  name: 'time',
}
