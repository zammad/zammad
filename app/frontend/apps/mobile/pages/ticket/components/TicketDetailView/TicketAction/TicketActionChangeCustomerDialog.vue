<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '@shared/components/Form/Form.vue'
import { type FormData, useForm } from '@shared/components/Form'
import {
  EnumObjectManagerObjects,
  type TicketCustomerUpdateInput,
} from '@shared/graphql/types'
import { closeDialog } from '@shared/composables/useDialog'
import { useTicketFormOganizationHandler } from '@shared/entities/ticket/composables/useTicketFormOrganizationHandler'
import { MutationHandler } from '@shared/server/apollo/handler'
import { convertToGraphQLId } from '@shared/graphql/utils'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import UserError from '@shared/errors/UserError'
import { useTicketCustomerUpdateMutation } from '@shared/entities/ticket/graphql/mutations/customerUpdate.api'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import { defineFormSchema } from '@mobile/form/defineFormSchema'
import type { TicketById } from '@shared/entities/ticket/types'
// No usage of "type" because of: https://github.com/typescript-eslint/typescript-eslint/issues/5468
import { TicketCustomerUpdateFormData } from '@shared/entities/ticket/types'
import { useConfirmationDialog } from '@mobile/components/CommonConfirmation'

export interface Props {
  name: string
  ticket: TicketById
}

const props = defineProps<Props>()

const { form, isDirty, isDisabled, canSubmit } = useForm()

const { waitForConfirmation } = useConfirmationDialog()

const cancelDialog = async () => {
  if (isDirty.value) {
    const confirmed = await waitForConfirmation(
      __('Are you sure? You have unsaved changes that will get lost.'),
    )

    if (!confirmed) return
  }

  closeDialog(props.name)
}

const formSchema = defineFormSchema([
  {
    name: 'customer_id',
    screen: 'edit',
    object: EnumObjectManagerObjects.Ticket,
    required: true,
  },
  {
    name: 'organization_id',
    screen: 'edit',
    object: EnumObjectManagerObjects.Ticket,
  },
])

const changeCustomerMutation = new MutationHandler(
  useTicketCustomerUpdateMutation({}),
)

const { notify } = useNotifications()

const changeCustomer = async (
  formData: FormData<TicketCustomerUpdateFormData>,
) => {
  const input = {
    customerId: convertToGraphQLId('User', formData.customer_id),
  } as TicketCustomerUpdateInput

  if (formData.organization_id) {
    input.organizationId = convertToGraphQLId(
      'Organization',
      formData.organization_id,
    )
  }

  try {
    const result = await changeCustomerMutation.send({
      ticketId: props.ticket.id,
      input,
    })

    if (result) {
      closeDialog(props.name)
      notify({
        type: NotificationTypes.Success,
        message: __('Ticket customer updated successfully.'),
      })
    }
  } catch (errors) {
    if (errors instanceof UserError) {
      notify({
        message: errors.generalErrors[0],
        type: NotificationTypes.Error,
      })
    }
  }
}
</script>

<template>
  <CommonDialog
    class="w-full"
    no-autofocus
    :name="name"
    :label="__('Change customer')"
  >
    <template #before-label>
      <button
        class="text-white"
        :class="{ 'opacity-50': isDisabled }"
        @click="cancelDialog"
      >
        {{ $t('Cancel') }}
      </button>
    </template>
    <template #after-label>
      <button
        :form="name"
        class="text-blue"
        :disabled="!canSubmit"
        :class="{ 'opacity-50': !canSubmit }"
      >
        {{ $t('Save') }}
      </button>
    </template>
    <Form
      :id="name"
      ref="form"
      class="w-full p-4"
      autofocus
      :schema="formSchema"
      :handlers="[useTicketFormOganizationHandler()]"
      :initial-entity-object="ticket"
      use-object-attributes
      @submit="changeCustomer($event as FormData<TicketCustomerUpdateFormData>)"
    />
  </CommonDialog>
</template>
