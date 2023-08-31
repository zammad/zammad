<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import {
  EnumObjectManagerObjects,
  type TicketCustomerUpdateInput,
} from '#shared/graphql/types.ts'
import { closeDialog } from '#shared/composables/useDialog.ts'
import { useTicketFormOganizationHandler } from '#shared/entities/ticket/composables/useTicketFormOrganizationHandler.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import UserError from '#shared/errors/UserError.ts'
import { useTicketCustomerUpdateMutation } from '#shared/entities/ticket/graphql/mutations/customerUpdate.api.ts'
import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonDialog from '#mobile/components/CommonDialog/CommonDialog.vue'
import { defineFormSchema } from '#mobile/form/defineFormSchema.ts'
import type {
  TicketById,
  TicketCustomerUpdateFormData,
} from '#shared/entities/ticket/types.ts'
import { waitForConfirmation } from '#shared/utils/confirmation.ts'

export interface Props {
  name: string
  ticket: TicketById
}

const props = defineProps<Props>()

const { form, isDirty, canSubmit } = useForm()

const cancelDialog = async () => {
  if (isDirty.value) {
    const confirmed = await waitForConfirmation(
      __('Are you sure? You have unsaved changes that will get lost.'),
      {
        buttonTitle: __('Discard changes'),
        buttonVariant: 'danger',
      },
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
  formData: FormSubmitData<TicketCustomerUpdateFormData>,
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
      <CommonButton transparent-background @click="cancelDialog">
        {{ $t('Cancel') }}
      </CommonButton>
    </template>
    <template #after-label>
      <CommonButton
        :form="name"
        :disabled="!canSubmit"
        variant="primary"
        type="submit"
        transparent-background
      >
        {{ $t('Save') }}
      </CommonButton>
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
      @submit="
        changeCustomer($event as FormSubmitData<TicketCustomerUpdateFormData>)
      "
    />
  </CommonDialog>
</template>
