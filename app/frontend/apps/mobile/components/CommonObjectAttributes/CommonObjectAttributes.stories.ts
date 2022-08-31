// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import CommonObjectAttributes, {
  type Props,
} from './CommonObjectAttributes.vue'

export default {
  title: 'Apps/Mobile/CommonObjectAttributes',
  component: CommonObjectAttributes,
}

const Template: Story<Props> = (args) => ({
  components: { CommonObjectAttributes },
  setup() {
    return { args }
  },
  template: '<CommonObjectAttributes v-bind="args"/> ',
})

export const Default = Template.bind({})
Default.args = {
  attributes: [
    {
      name: 'login',
      display: 'Login',
      dataType: 'input',
      dataOption: {
        type: 'text',
        maxlength: 100,
        null: true,
        autocapitalize: false,
        item_class: 'formGroup--halfSize',
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'organization_id',
      display: 'Organization',
      dataType: 'autocompletion_ajax',
      dataOption: {
        multiple: false,
        nulloption: true,
        null: true,
        relation: 'Organization',
        item_class: 'formGroup--halfSize',
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'address',
      display: 'Address',
      dataType: 'textarea',
      dataOption: {
        type: 'text',
        maxlength: 500,
        rows: 4,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'vip',
      display: 'VIP',
      dataType: 'boolean',
      dataOption: {
        null: true,
        default: false,
        item_class: 'formGroup--halfSize',
        options: {
          false: 'no',
          true: 'yes',
        },
        translate: true,
        permission: ['admin.user', 'ticket.agent'],
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'note',
      display: 'Note',
      dataType: 'richtext',
      dataOption: {
        type: 'text',
        maxlength: 5000,
        null: true,
        note: 'Notes are visible to agents only, never to customers.',
        no_images: true,
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'role_ids',
      display: 'Permissions',
      dataType: 'user_permission',
      dataOption: {
        null: false,
        item_class: 'checkbox',
        permission: ['admin.user'],
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
    {
      name: 'active',
      display: 'Active',
      dataType: 'active',
      dataOption: {
        null: true,
        default: true,
        permission: ['admin.user', 'ticket.agent'],
      },
      __typename: 'ObjectManagerFrontendAttribute',
    },
  ],
  object: {
    login: 'some_object',
    organization_id: 'Zammad',
    address: 'Berlin, Street, House',
    vip: true,
    note: 'note',
    role_ids: '1, 2',
    active: true,
  },
}
