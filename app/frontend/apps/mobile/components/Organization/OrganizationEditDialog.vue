<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { defineFormSchema } from '@mobile/form/composable'
import Form from '@shared/components/Form/Form.vue'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import type { ConfidentTake } from '@shared/types/utils'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import type { OrganizationQuery } from '@shared/graphql/types'
import { closeDialog } from '@shared/composables/useDialog'
import { MutationHandler } from '@shared/server/apollo/handler'
import { type FormData } from '@shared/components/Form/types'
import { shallowRef } from 'vue'
import type { FormKitNode } from '@formkit/core'
import { useOrganizationUpdateMutation } from '@mobile/entities/organization/graphql/mutations/update.api'

interface Props {
  name: string
  organization: ConfidentTake<OrganizationQuery, 'organization'>
}

const props = defineProps<Props>()

const schema = defineFormSchema([
  {
    name: 'name',
    required: true,
    object: EnumObjectManagerObjects.Organization,
  },
  {
    screen: 'edit',
    object: EnumObjectManagerObjects.Organization,
  },
])

const updateQuery = new MutationHandler(useOrganizationUpdateMutation({}))
const formElement = shallowRef<{ formNode: FormKitNode }>()

const submitForm = () => formElement.value?.formNode.submit()

interface OrganizationForm {
  domain: string
  domain_assignment: boolean
  note: string
  name: string
  shared: boolean
  active: boolean
}

const initialValue = {
  ...props.organization,
  ...props.organization.objectAttributeValues?.reduce(
    (acc, { attribute, value }) => ({ ...acc, [attribute.name]: value }),
    {},
  ),
}

const saveOrganization = async (formData: FormData<OrganizationForm>) => {
  const objectAttributeValues = props.organization.objectAttributeValues?.map(
    ({ attribute }) => {
      return {
        name: attribute.name,
        value: formData[attribute.name],
      }
    },
  )

  const result = await updateQuery.send({
    id: props.organization.id,
    input: {
      name: formData.name,
      domain: formData.domain,
      domainAssignment: formData.domain_assignment,
      note: formData.note,
      shared: formData.shared,
      active: formData.active,
      objectAttributeValues,
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
      id="edit-organization"
      ref="formElement"
      class="w-full p-4"
      :schema="schema"
      :initial-values="initialValue"
      use-object-attributes
      @submit="saveOrganization($event as FormData<OrganizationForm>)"
    />
  </CommonDialog>
</template>
