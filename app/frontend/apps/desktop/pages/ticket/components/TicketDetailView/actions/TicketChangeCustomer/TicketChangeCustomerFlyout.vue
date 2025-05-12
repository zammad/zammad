<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useTicketChangeCustomer } from '#shared/entities/ticket/composables/useTicketChangeCustomer.ts'
import { useTicketFormOrganizationHandler } from '#shared/entities/ticket/composables/useTicketFormOrganizationHandler.ts'
import type {
  TicketById,
  TicketCustomerUpdateFormData,
} from '#shared/entities/ticket/types.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

interface Props {
  ticket: TicketById
}

const props = defineProps<Props>()

const ticketChangeCustomerFlyoutName = 'ticket-change-customer'

const { form } = useForm()

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

const { changeCustomer } = useTicketChangeCustomer(toRef(props, 'ticket'), {
  onSuccess: () => closeFlyout(ticketChangeCustomerFlyoutName),
})
</script>

<template>
  <CommonFlyout
    header-icon="person"
    no-close-on-action
    :name="ticketChangeCustomerFlyoutName"
    :header-title="__('Change Customer')"
    :form="form"
    :footer-action-options="{
      actionButton: {
        type: 'submit',
      },
    }"
  >
    <Form
      id="form-change-customer"
      ref="form"
      should-autofocus
      :handlers="[useTicketFormOrganizationHandler()]"
      :initial-entity-object="ticket"
      use-object-attributes
      :schema="formSchema"
      @submit="
        changeCustomer($event as FormSubmitData<TicketCustomerUpdateFormData>)
      "
    />
  </CommonFlyout>
</template>
