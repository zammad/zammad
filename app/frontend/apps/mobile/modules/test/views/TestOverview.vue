<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable zammad/zammad-detect-translatable-string */

import Form from '@shared/components/Form/Form.vue'
import { defineFormSchema } from '@mobile/form/composable'

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
    type: 'select',
    name: 'select',
    label: 'Select',
    props: {
      link: '/tickets',
      options: [{ label: 'Label', value: 1 }],
    },
  },
  {
    type: 'treeselect',
    name: 'treeselect',
    label: 'Treeselect',
    props: {
      options: [{ label: 'Label', value: 1 }],
      link: '/tickets',
    },
  },
]
const linkSchemas = defineFormSchema(linkSchemaRaw)

const schema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    props: {
      columns: 2,
    },
    children: [
      {
        type: 'text',
        name: 'text22',
        label: 'Some_Label',
      },
      {
        type: 'text',
        name: 'text23',
        label: 'Some Label3',
      },
    ],
  },
  {
    isLayout: true,
    component: 'FormGroup',
    children: linkSchemaRaw,
  },
])
</script>

<template>
  <div class="p-4">
    <Form :schema="linkSchemas" />
    <Form :schema="schema" />
  </div>
</template>
