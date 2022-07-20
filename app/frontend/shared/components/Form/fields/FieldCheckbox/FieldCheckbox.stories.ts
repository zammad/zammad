// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'
import { CheckboxVariant } from './types'

export default {
  title: 'Form/Field/Checkbox',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    variant: {
      control: { type: 'select' },
      table: {
        defaultValue: {
          summary: CheckboxVariant.Default,
        },
      },
      options: [CheckboxVariant.Default, CheckboxVariant.Switch],
    },
    options: {
      name: 'options',
      type: { name: 'array', required: false },
      description:
        'An object of value/label pairs or an array of strings, or an array of objects that must contain a label and value property.',
      table: {
        type: { summary: 'Array/Object' },
        defaultValue: {
          summary: '[]',
        },
      },
      control: {
        type: 'object',
      },
    },
    onValue: {
      name: 'onValue',
      type: { name: 'string', required: false },
      description:
        'The value when the checkbox is checked (single checkboxes only).',
      table: {
        type: { summary: 'Boolean/String' },
        defaultValue: {
          summary: 'true',
        },
      },
      control: {
        type: 'text',
      },
    },
    offValue: {
      name: 'offValue',
      type: { name: 'string', required: false },
      description:
        'The value when the checkbox is unchecked (single checkboxes only).',
      table: {
        type: { summary: 'Boolean/String' },
        defaultValue: {
          summary: 'false',
        },
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
          '[FormKit Built-In - Password](https://formkit.com/inputs/checkbox) + Variant for switch',
      },
    },
  },
}

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="checkbox" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Checkbox',
  name: 'checkbox',
}

export const VariantSwitch = Template.bind({})
VariantSwitch.args = {
  label: 'Checkbox',
  name: 'checkbox',
  variant: CheckboxVariant.Switch,
}
