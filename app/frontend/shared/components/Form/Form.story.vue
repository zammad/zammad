<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from './Form.vue'
</script>

<template>
  <Story title="Form" group="form">
    <Variant title="Default">
      <Form
        :schema="[
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
        ]"
      />
    </Variant>
    <Variant title="Login">
      <Form
        :schema="[
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
            label: 'Password',
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
        ]"
      />
    </Variant>
  </Story>
</template>
