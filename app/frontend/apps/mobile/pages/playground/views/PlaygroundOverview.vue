<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable zammad/zammad-detect-translatable-string */
import { computed, reactive, ref } from 'vue'

import { EnumSecurityStateType } from '#shared/components/Form/fields/FieldSecurity/types.ts'
import Form from '#shared/components/Form/Form.vue'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonButtonGroup from '#mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import CommonStepper from '#mobile/components/CommonStepper/CommonStepper.vue'
import LayoutHeader from '#mobile/components/layout/LayoutHeader.vue'
import { useDialog } from '#mobile/composables/useDialog.ts'
import { useUserCreate } from '#mobile/entities/user/composables/useUserCreate.ts'

const linkSchemaRaw = [
  {
    type: 'externalDataSource',
    name: 'external_data_source',
    label: 'External Data Source',
    object: 'Ticket',
    required: true,
  },
  {
    type: 'security',
    name: 'security',
    label:
      'Security Long Name Very long Not Truncated Oh no Please Its Too Long',
    required: true,
    props: {
      securityAllowed: {
        [EnumSecurityStateType.Smime]: ['sign', 'encryption'],
        [EnumSecurityStateType.Pgp]: ['encryption'],
      },
    },
  },
  {
    type: 'editor',
    name: 'editor',
    label: 'Editor',
    required: true,
    // props: editorProps,
  },
  {
    type: 'textarea',
    name: 'textarea',
    id: 'textarea',
    label: 'Textarea',
  },
  {
    type: 'toggle',
    name: 'toggle',
    label: 'Toggle',
    required: true,
    // disabled: true,
    props: {
      value: false,
      variants: {
        true: 'Yes',
        false: 'No',
      },
    },
  },
  {
    type: 'text',
    name: 'some_input',
    label: 'Input',
    disabled: true,
    required: true,
  },
  {
    type: 'textarea',
    name: 'select',
    label: 'Textarea',
    required: true,
  },
  {
    type: 'text',
    name: 'some_input_link',
    label: 'Linked',
    props: {
      link: '/',
    },
  },
  {
    type: 'datetime',
    name: 'some_input_date',
    label: 'Date',
    props: {
      link: '/',
      clearable: true,
    },
    required: true,
  },
  {
    type: 'tags',
    name: 'tags',
    label: 'Tags',
    props: {
      link: '/',
      options: [
        { label: 'test', value: 'test' },
        { label: 'support', value: 'support' },
        { label: 'paid', value: 'paid' },
        { label: 'paid2', value: 'paid2' },
        { label: 'paid3', value: 'paid3' },
        { label: 'paid4', value: 'paid4' },
        { label: 'paid5', value: 'paid5' },
        { label: 'paid6', value: 'paid6' },
        { label: 'paid7', value: 'paid7' },
        { label: 'paid8', value: 'paid8' },
        { label: 'paid9', value: 'paid9' },
        { label: 'paid10', value: 'paid10' },
        { label: 'paid11', value: 'paid11' },
      ],
      canCreate: true,
    },
  },
  {
    type: 'treeselect',
    name: 'treeselect',
    label: 'TreeSelect',
    value: [0, 3, 5, 6, 1, 2, 8, 7],
    props: {
      clearable: true,
      multiple: true,
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
  {
    type: 'treeselect',
    name: 'treeselect_2',
    label: 'TreeSelect 2',
    props: {
      link: '/',
      options: [
        {
          value: 0,
          label: 'Item A',
        },
      ],
    },
  },
  {
    type: 'select',
    name: 'select_1',
    label: 'Select 1',
    disabled: true,
    props: {
      link: '/',
      options: [
        {
          value: 0,
          label: 'Item A',
        },
      ],
    },
  },
  {
    type: 'select',
    name: 'select_2',
    label: 'Select 2',
    props: {
      link: '/',
      multiple: true,
      options: [
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
      ],
    },
  },
  {
    type: 'autocomplete',
    name: 'autocomplete',
    label: 'AutoComplete',
    props: {
      sorting: 'label',
      link: '/tickets',
      action: '/tickets',
      actionIcon: 'new-customer',
      gqlQuery: `
query autocompleteSearchUser($input: AutocompleteSearchInput!) {
  autocompleteSearchUser(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
  }
}
`,
    },
  },
  {
    type: 'recipient',
    name: 'recipient_email',
    label: 'Recipient Email',
  },
  {
    type: 'recipient',
    name: 'recipient_phone',
    label: 'Recipient Phone',
    props: {
      contact: 'phone',
    },
  },
  {
    type: 'organization',
    name: 'organization',
    label: 'Organization',
    props: {
      gqlQuery: `
query autocompleteSearchUser($input: AutocompleteSearchInput!) {
  autocompleteSearchUser(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
  }
}
`,
    },
  },
  {
    type: 'customer',
    name: 'customer',
    label: 'Customer',
    props: {
      gqlQuery: `
query autocompleteSearchUser($input: AutocompleteSearchInput!) {
  autocompleteSearchUser(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
  }
}
`,
    },
  },
]
const linkSchemas = defineFormSchema(linkSchemaRaw, { showDirtyMark: true })

const schema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        type: 'file',
        name: 'file',
        // label: 'File',
        props: {
          multiple: true,
        },
      },
    ],
  },
])

const dialog = useDialog({
  name: 'dialog',
  component: () => import('#mobile/components/CommonDialog/CommonDialog.vue'),
})

const { openCreateUserDialog } = useUserCreate()

const currentStep = ref('step2')
const steps = {
  step1: {
    label: '1',
    order: 1,
    errorCount: 0,
    valid: true,
    disabled: false,
    completed: true,
  },
  step2: {
    label: '2',
    order: 2,
    errorCount: 0,
    valid: true,
    disabled: true,
    completed: false,
  },
  step3: {
    label: '3',
    order: 3,
    errorCount: 0,
    valid: true,
    completed: true,
    disabled: true,
  },
  step4: {
    label: '4',
    order: 4,
    errorCount: 3,
    valid: false,
    completed: false,
    disabled: true,
  },
}

const editorProps = reactive({
  contentType: 'text/plain',
  meta: {
    footer: {
      text: '/AB',
      maxlength: 276,
      warningLength: 30,
    },
  },
})

const updateEditorProps = () => {
  editorProps.contentType =
    editorProps.contentType === 'text/plain' ? 'text/html' : 'text/plain'
}

const editorSchema = defineFormSchema([
  {
    type: 'editor',
    name: 'editor',
    label: 'Editor',
    required: true,
    props: Object.keys(editorProps).reduce(
      (acc, key) => {
        acc[key] = computed(() => editorProps[key as keyof typeof editorProps])
        return acc
      },
      {} as Record<string, unknown>,
    ),
  },
])
const logSubmit = console.log
</script>

<template>
  <div class="p-4">
    <LayoutHeader title="Playground">
      <template #before>1 / 3</template>
      <template #after>
        <CommonButton class="flex-1 px-4 py-2" variant="secondary"
          >Click
        </CommonButton>
      </template>
    </LayoutHeader>
    <h2 class="text-xl font-bold">Buttons</h2>
    <div class="mt-2 flex gap-3">
      <CommonButton class="flex-1 py-2" variant="primary" />
      <CommonButton class="flex-1 py-2" variant="secondary" />
    </div>
    <div class="my-4 flex gap-3">
      <CommonButton class="flex-1 py-2" variant="submit" />
      <CommonButton class="flex-1 py-2" variant="danger" />
    </div>
    <h3 class="text-gray mb-2 mt-2 text-lg font-semibold">
      With transparent background
    </h3>
    <div class="flex gap-3">
      <CommonButton
        class="flex-1 py-2"
        variant="primary"
        transparent-background
      />
      <CommonButton
        class="flex-1 py-2"
        variant="secondary"
        transparent-background
      />
    </div>
    <div class="my-4 flex gap-3">
      <CommonButton
        class="flex-1 py-2"
        variant="submit"
        transparent-background
      />
      <CommonButton
        class="flex-1 py-2"
        variant="danger"
        transparent-background
      />
    </div>

    <button @click="dialog.toggle({ name: 'dialog', label: 'Hello World' })">
      Dialog
    </button>

    <button type="button" @click="updateEditorProps">
      CHANGE EDITOR PROPS
    </button>

    <button form="form">Submit</button>

    <CommonStepper v-model="currentStep" class="mx-20" :steps="steps" />

    <button @click="openCreateUserDialog()">Create user</button>

    <Form :schema="editorSchema" @submit="logSubmit" />

    <CommonButtonGroup
      class="py-4"
      mode="full"
      model-value="subscribe"
      :options="[
        { label: 'Merge tickets', icon: 'home' },
        { label: 'Subscribe', icon: 'home', value: 'subscribe' },
        { label: 'Ticket info', icon: 'home' },
      ]"
    />

    <Form id="form" :schema="linkSchemas" />
    <Form :schema="schema" />

    <FormKit
      type="radio"
      :buttons="true"
      :options="[
        { label: 'Incoming Phone', value: 1, icon: 'phone-in' },
        { label: 'Outgoing Phone', value: 2, icon: 'phone-out' },
        { label: 'Send Email', value: 3, icon: 'mail-out' },
      ]"
    />

    <FormKit
      wrapper-class="mt-6 flex grow justify-center items-center"
      input-class="py-2 px-4 w-full h-14 text-xl rounded-xl select-none"
      variant="submit"
      type="submit"
      prefix-icon="arrow-right"
      suffix-icon="arrow-left"
    >
      {{ $t('Sign in') }}
    </FormKit>
  </div>
</template>
