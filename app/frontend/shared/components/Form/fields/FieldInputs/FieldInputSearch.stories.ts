// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'

export default {
  title: 'Form/Field/Inputs/Search',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
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
          '[FormKit Built-In - Search](https://formkit.com/inputs/search)',
      },
    },
  },
}

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="search" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Search',
  name: 'search',
  placeholder: 'Search something...',
}
