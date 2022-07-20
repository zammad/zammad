// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'

export default {
  title: 'Form/Field/Textarea',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    cols: {
      name: 'cols',
      type: { name: 'number', required: false },
      desciption: '',
      table: {
        type: { summary: 'number' },
        defaultValue: {
          summary: '20',
        },
      },
      control: {
        type: 'number',
      },
    },
    rows: {
      name: 'rows',
      type: { name: 'number', required: false },
      desciption: '',
      table: {
        type: { summary: 'number' },
      },
      control: {
        type: 'number',
      },
    },
    maxlength: {
      name: 'maxlength',
      type: { name: 'number', required: false },
      desciption: '',
      table: {
        type: { summary: 'number' },
      },
      control: {
        type: 'number',
      },
    },
    minlength: {
      name: 'minlength',
      type: { name: 'number', required: false },
      desciption: '',
      table: {
        type: { summary: 'number' },
      },
      control: {
        type: 'number',
      },
    },
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
          '[FormKit Built-In - Textarea](https://formkit.com/inputs/textarea)',
      },
    },
  },
}

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="textarea" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Text',
  name: 'textarea',
}
