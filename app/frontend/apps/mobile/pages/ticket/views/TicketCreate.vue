<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
// import { defineFormSchema } from '@mobile/form/composable'
import Form from '@shared/components/Form/Form.vue'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '@shared/graphql/types'
// import { computed } from 'vue'

// fixed fields? (e.g. title)
// skip fields for mobile? (e.g. user_permission for user create/edit)
// get only one screen for placement

// title fixed
// create_top
// some article fields

// create_middle

// create_bottom

const additionalFormSchema = [
  { name: 'title', required: true, object: EnumObjectManagerObjects.Ticket },
  { screen: 'create_top', object: EnumObjectManagerObjects.Ticket },
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'body',
        label: 'TESTING',
        object: EnumObjectManagerObjects.TicketArticle,
      },
    ],
  },
  { screen: 'create_top', object: EnumObjectManagerObjects.TicketArticle },
  { screen: 'create_middle', object: EnumObjectManagerObjects.Ticket },
]
</script>

<template>
  <div>
    <Form
      v-if="additionalFormSchema.length > 0"
      id="create"
      ref="form"
      class="text-left"
      :schema="additionalFormSchema"
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate"
      use-object-attributes
    ></Form>
  </div>
</template>
