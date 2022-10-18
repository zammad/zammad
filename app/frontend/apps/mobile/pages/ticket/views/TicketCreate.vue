<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
// import { defineFormSchema } from '@mobile/form/composable'
import Form from '@shared/components/Form/Form.vue'
import type { FormSchemaField } from '@shared/components/Form/types'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '@shared/graphql/types'
import { ref } from 'vue'
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
  {
    name: 'title',
    required: true,
    object: EnumObjectManagerObjects.Ticket,
    screen: 'create_top',
  },
  { screen: 'create_top', object: EnumObjectManagerObjects.Ticket },
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'body',
        label: 'TESTING',
        screen: 'create_top',
        object: EnumObjectManagerObjects.TicketArticle,
      },
    ],
  },
  { screen: 'create_top', object: EnumObjectManagerObjects.TicketArticle },
  { screen: 'create_middle', object: EnumObjectManagerObjects.Ticket },
]

const submit = (data: unknown) => {
  console.log('VALUES', data)
}

const changeHiddenFields = ref<Record<string, Partial<FormSchemaField>>>({})

const changeHidden = () => {
  changeHiddenFields.value.type = {
    hidden: false,
  }

  console.log('CHANGE HIDDEN', changeHiddenFields.value)
}
</script>

<template>
  <div>
    <Form
      v-if="additionalFormSchema.length > 0"
      id="create"
      ref="form"
      class="text-left"
      :schema="additionalFormSchema"
      :change-fields="changeHiddenFields"
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate"
      use-object-attributes
      @submit="submit"
    >
      <template #after-fields>
        <FormKit type="submit">
          {{ $t('Create') }}
        </FormKit>
      </template>
    </Form>
    <br />
    <FormKit type="button" @click="changeHidden">Change Hidden</FormKit>
  </div>
</template>
