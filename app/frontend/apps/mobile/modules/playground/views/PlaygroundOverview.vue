<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable zammad/zammad-detect-translatable-string */

import Form from '@shared/components/Form/Form.vue'
import { defineFormSchema } from '@mobile/form/composable'
import { useDialog } from '@shared/composables/useDialog'

const linkSchemaRaw = [
  {
    type: 'date',
    name: 'date',
    label: 'Date_Input',
    props: {
      link: '/tickets',
    },
  },
  {
    type: 'search',
    name: 'search',
    // label: 'Date_Input',
    props: {
      link: '/tickets',
    },
  },
  {
    type: 'select',
    name: 'select',
    label: 'Select',
    props: {
      // multiple: true,
      link: '/tickets',
      options: [
        {
          value: 0,
          label: 'Item A',
          disabled: true,
        },
        {
          value: 1,
          label: 'Item B',
        },
        {
          value: 2,
          label: 'Item C',
        },
      ],
    },
  },
  {
    type: 'treeselect',
    name: 'treeselect',
    label: 'Treeselect',
    props: {
      options: [
        {
          value: 0,
          label: 'Item A',
          children: [
            {
              value: 1,
              label: 'Item 1',
              children: [
                {
                  value: 2,
                  label: 'Item I',
                },
                {
                  value: 3,
                  label: 'Item II',
                },
                {
                  value: 4,
                  label: 'Item III',
                },
              ],
            },
            {
              value: 5,
              label: 'Item 2',
              children: [
                {
                  value: 6,
                  label: 'Item IV',
                },
              ],
            },
            {
              value: 7,
              label: 'Item 3',
            },
          ],
        },
        {
          value: 8,
          label: 'Item B',
        },
        {
          value: 9,
          label: 'Ítem C',
        },
      ],
      link: '/tickets',
    },
  },
]
const linkSchemas = defineFormSchema(linkSchemaRaw)

const schema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormLayout',
    props: {
      columns: 2,
    },
    children: [
      {
        isLayout: true,
        component: 'FormGroup',
        children: [
          {
            type: 'text',
            name: 'text22',
            label: 'Some_Label',
          },
        ],
      },
      {
        type: 'text',
        name: 'text23',
        label: 'Some Label3',
      },
    ],
  },
])

const dialog = useDialog({
  name: 'dialog',
  component: async () =>
    import('@mobile/components/CommonDialog/CommonDialog.vue'),
})
</script>

<template>
  <div class="p-4">
    <button @click="dialog.toggle({ name: 'dialog', label: 'Hello World' })">
      Dialog
    </button>

    <Form :schema="linkSchemas" />
    <Form :schema="schema" />
  </div>
</template>
