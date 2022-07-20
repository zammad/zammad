// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { ref } from 'vue'
import CommonSelect, { type Props } from './CommonSelect.vue'

export default {
  title: 'CommonSelect',
  component: CommonSelect,
}

const options = [
  {
    value: 0,
    label: 'Item A',
  },
  {
    value: 1,
    label: 'Item B',
  },
  {
    value: 2,
    label: 'Item C',
  },
]

const html = String.raw

const Template: Story<Props> = (args: Props) => ({
  components: { CommonSelect },
  setup() {
    const modelValue = ref()
    return { args, modelValue }
  },
  template: html` <CommonSelect
    v-model="modelValue"
    v-bind="args"
    v-slot="{ open }"
  >
    <button @click="open">Click Me!</button>
    <div>Selected: {{ modelValue }}</div>
  </CommonSelect>`,
})

export const Default = Template.bind({})
Default.args = {
  options,
}

export const Multiple = Template.bind({})
Multiple.args = {
  options,
  multiple: true,
}
