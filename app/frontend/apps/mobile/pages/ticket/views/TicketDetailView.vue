<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { redirectToError } from '@mobile/router/error'
import type {
  TicketUpdatesSubscription,
  TicketUpdatesSubscriptionVariables,
} from '@shared/graphql/types'
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
import { computed, provide, ref, Teleport } from 'vue'
import { noop } from 'lodash-es'
import { onBeforeRouteLeave, RouterView, useRouter } from 'vue-router'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import useConfirmation from '@mobile/components/CommonConfirmation/composable'
import { convertToGraphQLId } from '@shared/graphql/utils'
import { useTicketEdit } from '../composable/useTicketEdit'
import { TICKET_INFORMATION_SYMBOL } from '../composable/useTicketInformation'
import { useTicketQuery } from '../graphql/queries/ticket.api'
import { TicketUpdatesDocument } from '../graphql/subscriptions/ticketUpdates.api'

interface Props {
  internalId: string
}

const props = defineProps<Props>()
const ticketId = computed(() => convertToGraphQLId('Ticket', props.internalId))

const MENTIONS_LIMIT = 5

const ticketQuery = new QueryHandler(
  useTicketQuery(() => ({
    ticketId: ticketId.value,
    mentionsCount: MENTIONS_LIMIT,
  })),
  { errorShowNotification: false },
)

ticketQuery.subscribeToMore<
  TicketUpdatesSubscriptionVariables,
  TicketUpdatesSubscription
>(() => ({
  document: TicketUpdatesDocument,
  variables: {
    ticketId: ticketId.value,
  },
  // we already redirect on query error
  onError: noop,
}))

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

const { form, canSubmit, isDirty } = useForm()
const { initialTicketValue, editTicket } = useTicketEdit(ticket, form)
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

const canUpdateTicket = computed(() => !!ticket.value?.policy.update)

provide(TICKET_INFORMATION_SYMBOL, {
  ticketQuery,
  ticket,
  form,
  formVisible,
  canSubmitForm: canSubmit,
  canUpdateTicket,
})

const { waitForConfirmation } = useConfirmation()

onBeforeRouteLeave(async () => {
  if (!isDirty.value) return true

  const confirmed = await waitForConfirmation(
    __('Are you sure? You have unsaved changes that will get lost.'),
  )

  return confirmed
})

const ticketEditSchema = [
  {
    isLayout: true,
    component: 'FormGroup',
    props: {
      showDirtyMark: true,
    },
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
