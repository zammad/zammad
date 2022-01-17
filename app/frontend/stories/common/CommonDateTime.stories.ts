// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonDateTime from '@common/components/common/CommonDateTime.vue'
import { Story } from '@storybook/vue3'

export default {
  title: 'Common/DateTime',
  component: CommonDateTime,
  args: {
    dateTime: '',
    customFormat: '',
  },
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
    customFormat: {
      control: { type: 'select' },
      options: ['absolute', 'relative'],
    },
  },
}

const Template: Story = (args) => ({
  components: { CommonDateTime },
  setup() {
    return { args }
  },
  template: '<CommonDateTime v-bind="args"/>',
})

export const AbsoluteDateTime = Template.bind({})
AbsoluteDateTime.args = {
  dateTime: '2020-10-10 10:10:11',
  customFormat: 'absolute',
}

export const RelativeDateTime = Template.bind({})
RelativeDateTime.args = {
  dateTime: '2020-10-10 10:10:11',
  customFormat: 'relative',
}
