<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { redirectToError } from '@mobile/router/error'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import { ErrorStatusCodes } from '@shared/types/error'
import Form from '@shared/components/Form/Form.vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { useForm } from '@shared/components/Form'
import type { FormData } from '@shared/components/Form/types'
import { computed, provide, ref } from 'vue'
import { onBeforeRouteLeave, RouterView, useRouter } from 'vue-router'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import { useSessionStore } from '@shared/stores/session'
import useConfirmation from '@mobile/components/CommonConfirmation/composable'
import { useTicketEdit } from '../composable/useTicketEdit'
import { TICKET_INFORMATION_SYMBOL } from '../composable/useTicketInformation'
import { useTicketQuery } from '../graphql/queries/ticket.api'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

const MENTIONS_LIMIT = 5

const ticketQuery = new QueryHandler(
  useTicketQuery(() => ({
    ticketInternalId: Number(props.internalId),
    mentionsCount: MENTIONS_LIMIT,
  })),
  { errorShowNotification: false },
)

const ticketResult = ticketQuery.result()
const ticket = computed(() => ticketResult.value?.ticket)
const formVisible = ref(false)

const router = useRouter()

ticketQuery.onError(() => {
  return redirectToError(router, {
    statusCode: ErrorStatusCodes.Forbidden,
    message: __('Sorry, but you have insufficient rights to open this page.'),
  })
})

const { initialTicketValue, editTicket } = useTicketEdit(ticket)
const { form, isValid, isDisabled, isDirty } = useForm()
const { notify } = useNotifications()

const submitForm = async (formData: FormData) => {
  const result = await editTicket(formData)

  if (result) {
    notify({
      type: NotificationTypes.Success,
      message: __('Ticket updated successfully.'),
    })
  }
}

const session = useSessionStore()
// TODO use policies
// app/assets/javascripts/app/models/ticket.coffee:328
const canUpdateTicket = computed(() => {
  if (
    session.userId === ticket.value?.owner.id ||
    // TODO should check for agent groups access
    session.hasPermission('ticket.agent')
  ) {
    return true
  }
  if (!session.hasPermission('ticket.customer')) return false
  return session.userId === ticket.value?.customer.id
})

const canSubmitForm = computed(() => {
  return isDirty.value && isValid.value && !isDisabled.value
})

provide(TICKET_INFORMATION_SYMBOL, {
  ticketQuery,
  ticket,
  form,
  formVisible,
  canSubmitForm,
  canUpdateTicket,
})

const { waitForConfirmation } = useConfirmation()

onBeforeRouteLeave(async () => {
  if (!isDirty.value) return true

  // TODO store state in global storage instead of this
  const confirmed = await waitForConfirmation(
    __('Are you sure? You have unsaved changes that will get lost.'),
  )

  return confirmed
})

const ticketEditSchema = [
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'title',
        type: 'text',
        label: __('Ticket title'),
        required: true, // TODO core workflow resets it
      },
      {
        screen: 'edit',
        object: EnumObjectManagerObjects.Ticket,
      },
    ],
  },
]
</script>

<template>
  <RouterView />
  <!-- submit form is always present in the DOM, so we can access FormKit validity state -->
  <!-- if it's visible, it's moved to the [data-ticket-edit-form] element, which is in TicketInformationDetail -->
  <Teleport
    v-if="canUpdateTicket"
    :to="formVisible ? '[data-ticket-edit-form]' : 'body'"
  >
    <CommonLoader
      :class="formVisible ? 'visible' : 'hidden'"
      :loading="!ticket"
    >
      <Form
        v-if="initialTicketValue"
        id="form-ticket-edit"
        :key="ticket?.id || 'null'"
        ref="form"
        :schema="ticketEditSchema"
        :initial-values="initialTicketValue"
        :initial-entity-object="ticket"
        :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketEdit"
        use-object-attributes
        :aria-hidden="!formVisible"
        :class="formVisible ? 'visible' : 'hidden'"
        :on-submit="submitForm"
      />
    </CommonLoader>
  </Teleport>
</template>
