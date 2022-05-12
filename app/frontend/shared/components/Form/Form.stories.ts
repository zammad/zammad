// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import Form, { type Props } from './Form.vue'

export default {
  title: 'Form/Form',
  component: Form,
}

const Template: Story<Props> = (args: Props) => ({
  components: { Form },
  setup() {
    return { args }
  },
  template: '<Form v-bind="args"/> ',
})

export const Default = Template.bind({})
Default.args = {
  schema: [
    {
      type: 'text',
      name: 'title',
      label: 'Title',
    },
    {
      type: 'textarea',
      name: 'text',
      label: 'Text',
    },
  ],
}

export const Login = Template.bind({})
Login.args = {
  schema: [
    {
      type: 'text',
      name: 'login',
      label: 'Username / Email',
      placeholder: 'Please enter your username or email address',
      inputClass: 'block mt-1 w-1/2 h-14 text-sm rounded',
      validation: 'required',
    },
    {
      type: 'password',
      label: __('Password'),
      name: 'password',
      placeholder: 'Please enter your password',
      inputClass: 'block mt-1 w-1/2 h-14 text-sm rounded',
      validation: 'required',
    },
    {
      isLayout: true,
      element: 'div',
      attrs: {
        class: 'mt-2 w-1/2 flex grow items-center justify-between',
      },
      children: [
        {
          type: 'checkbox',
          label: 'Remember me',
          name: 'remember_me',
          wrapperClass: 'inline-flex items-center',
          innerClass: 'mr-2',
        },
        {
          isLayout: true,
          component: 'CommonLink',
          props: {
            class: 'text-right',
            link: '#',
          },
          children: 'Forgot password?',
        },
      ],
    },
  ],
}
