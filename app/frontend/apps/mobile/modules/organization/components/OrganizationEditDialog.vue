<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { defineFormSchema } from '@mobile/form/composable'
import Form from '@shared/components/Form/Form.vue'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import { CheckboxVariant } from '@shared/components/Form/fields/FieldCheckbox'
import type { ConfidentTake } from '@shared/types/utils'
import { OrganizationInput } from '@shared/graphql/types'
import type { OrganizationQuery } from '@shared/graphql/types'
import { closeDialog } from '@shared/composables/useDialog'
import { MutationHandler } from '@shared/server/apollo/handler'
import { shallowRef } from 'vue'
import type { FormKitNode } from '@formkit/core'
import { useOrganizationUpdateMutation } from '../graphql/mutations/update.api'

interface Props {
  name: string
  organization: ConfidentTake<OrganizationQuery, 'organization'>
}

const props = defineProps<Props>()

// TODO get from backend
const schema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        type: 'checkbox',
        name: 'shared',
        props: {
          variant: CheckboxVariant.Switch,
        },
        label: __('Shared organization'),
        value: props.organization.shared,
      },
      {
        type: 'checkbox',
        name: 'domainAssignment',
        props: {
          variant: CheckboxVariant.Switch,
        },
        label: __('Domain based assignment'),
        value: props.organization.domainAssignment,
      },
      // TODO disabled based on domainAssignment
      {
        type: 'text',
        name: 'domain',
        label: __('Domain'),
      },
    ],
  },
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        type: 'textarea',
        name: 'note',
        label: __('Note'),
        value: props.organization.note,
      },
    ],
  },
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        type: 'checkbox',
        name: 'active',
        props: {
          variant: CheckboxVariant.Switch,
        },
        label: __('Active'),
        value: props.organization.active,
      },
    ],
  },
])

const updateQuery = new MutationHandler(useOrganizationUpdateMutation({}))
const formElement = shallowRef<{ formNode: FormKitNode }>()

const submitForm = () => formElement.value?.formNode.submit()

const saveOrganization = async (input: OrganizationInput) => {
  const result = await updateQuery.send({
    id: props.organization.id,
    input: {
      domain: input.domain,
      domainAssignment: input.domainAssignment,
      note: input.note,
      shared: input.shared,
      active: input.active,
    },
  })
  // close only if there are no errors
  if (result) {
    closeDialog(props.name)
  }
}
</script>

<template>
  <CommonDialog :label="__('Edit')" :name="name">
    <template #before-label>
      <button class="text-blue" tabindex="0" @click="closeDialog(name)">
        {{ i18n.t('Cancel') }}
      </button>
    </template>
    <template #after-label>
      <button class="text-blue" tabindex="0" @click="submitForm()">
        {{ i18n.t('Save') }}
      </button>
    </template>
    <Form
      ref="formElement"
      class="w-full p-4"
      :schema="schema"
      @submit="saveOrganization($event as OrganizationInput)"
    />
  </CommonDialog>
</template>
