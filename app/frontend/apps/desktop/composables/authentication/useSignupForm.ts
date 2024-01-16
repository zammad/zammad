// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export const useSignupForm = () => {
  const signupSchema = [
    {
      isLayout: true,
      element: 'div',
      attrs: {
        class: 'grid grid-cols-2 gap-y-2.5 gap-x-3',
      },
      children: [
        {
          name: 'firstname',
          label: __('First name'),
          type: 'text',
          outerClass: 'col-span-1',
          props: {
            maxLength: 150,
          },
        },
        {
          name: 'lastname',
          label: __('Last name'),
          type: 'text',
          outerClass: 'col-span-1',
          props: {
            maxLength: 150,
          },
        },
        {
          name: 'email',
          label: __('Email'),
          type: 'email',
          validation: 'email',
          outerClass: 'col-span-2',
          props: {
            maxLength: 150,
          },
          required: true,
        },
        {
          name: 'password',
          label: __('Password'),
          type: 'password',
          outerClass: 'col-span-1',
          props: {
            maxLength: 1001,
          },
          required: true,
        },
        {
          name: 'password_confirm',
          label: __('Confirm password'),
          type: 'password',
          validation: 'confirm',
          outerClass: 'col-span-1',
          props: {
            maxLength: 1001,
          },
          required: true,
        },
      ],
    },
  ]

  return {
    signupSchema,
  }
}
