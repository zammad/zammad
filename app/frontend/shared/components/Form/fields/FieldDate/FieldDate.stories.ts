// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'

export default {
  title: 'Form/Field/Date',
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
    futureOnly: {
      name: 'futureOnly',
      type: { name: 'boolean', required: false },
      desciption: '',
      table: {
        type: { summary: 'false' },
      },
      control: {
        type: 'boolean',
      },
      description: 'Disables all days before tomorrow.',
    },
    minDate: {
      name: 'minDate',
      type: { name: 'string', required: false },
      desciption: '',
      table: {
        type: { summary: 'string' },
      },
      control: {
        type: 'text',
      },
    },
    maxDate: {
      name: 'maxDate',
      type: { name: 'string', required: false },
      desciption: '',
      table: {
        type: { summary: 'string' },
      },
      control: {
        type: 'text',
      },
    },
  },
}

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
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
