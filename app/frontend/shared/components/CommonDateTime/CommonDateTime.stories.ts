// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import CommonDateTime, { type Props } from './CommonDateTime.vue'

export default {
  title: 'Shared/DateTime',
  component: CommonDateTime,
  argTypes: {
    dateTime: {
      type: {
        name: 'string',
        required: true,
      },
      control: {
        type: 'date',
      },
    },
    format: {
      control: { type: 'select' },
      options: ['absolute', 'relative'],
    },
  },
}

const Template: Story<Props> = (args: Props) => ({
  components: { CommonDateTime },
  setup() {
    return { args }
  },
  template: '<CommonDateTime v-bind="args"/>',
})

export const AbsoluteDateTime = Template.bind({})
AbsoluteDateTime.args = {
  dateTime: '2020-10-10 10:10:11',
  format: 'absolute',
}

export const RelativeDateTime = Template.bind({})
RelativeDateTime.args = {
  dateTime: '2020-10-10 10:10:11',
  format: 'relative',
}
