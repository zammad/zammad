<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, provide, ref, reactive } from 'vue'
import { onBeforeRouteLeave, RouterView, useRouter } from 'vue-router'
import { noop } from 'lodash-es'
import type {
  TicketUpdatesSubscription,
  TicketUpdatesSubscriptionVariables,
} from '@shared/graphql/types'
import { EnumFormUpdaterId } from '@shared/graphql/types'
import UserError from '@shared/errors/UserError'
import { QueryHandler } from '@shared/server/apollo/handler'
import { ErrorStatusCodes } from '@shared/types/error'
import Form from '@shared/components/Form/Form.vue'
import { useForm, FormData } from '@shared/components/Form'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import { convertToGraphQLId } from '@shared/graphql/utils'
import { useApplicationStore } from '@shared/stores/application'
import { useTicketView } from '@shared/entities/ticket/composables/useTicketView'
import type { TicketInformation } from '@mobile/entities/ticket/types'
import { redirectToError } from '@mobile/router/error'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import useConfirmation from '@mobile/components/CommonConfirmation/composable'
import { useTicketEdit } from '../composable/useTicketEdit'
import { TICKET_INFORMATION_SYMBOL } from '../composable/useTicketInformation'
import { useTicketQuery } from '../graphql/queries/ticket.api'
import { TicketUpdatesDocument } from '../graphql/subscriptions/ticketUpdates.api'
import { useTicketArticleReply } from '../composable/useTicketArticleReply'
import { useTicketEditForm } from '../composable/useTicketEditForm'
import { useTicketLiveUser } from '../composable/useTicketLiveUser'

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

const ticketResult = ticketQuery.result()
const ticket = computed(() => ticketResult.value?.ticket)

ticketQuery.subscribeToMore<
  TicketUpdatesSubscriptionVariables,
  TicketUpdatesSubscription
>(() => ({
  document: TicketUpdatesDocument,
  variables: {
    ticketId: ticketId.value,
  },
  onError: noop,
}))

const formLocation = ref('body')
const formVisible = computed(() => formLocation.value !== 'body')

const router = useRouter()

ticketQuery.onError(() => {
  return redirectToError(router, {
    statusCode: ErrorStatusCodes.Forbidden,
    message: __('Sorry, but you have insufficient rights to open this page.'),
  })
})

const { form, canSubmit, isDirty, formSubmit } = useForm()

const { initialTicketValue, isTicketFormGroupValid, editTicket } =
  useTicketEdit(ticket, form)

const {
  newTicketArticleRequested,
  newTicketArticlePresent,
  isArticleFormGroupValid,
  openArticleReplyDialog,
} = useTicketArticleReply(ticket, form)

const {
  currentArticleType,
  ticketEditSchema,
  articleTypeHandler,
  articleTypeSelectHandler,
} = useTicketEditForm(ticket)

const { isTicketAgent } = useTicketView(ticket)

const { notify } = useNotifications()

const submitForm = async (formData: FormData) => {
  const updateForm = currentArticleType.value?.updateForm

  if (updateForm) {
    formData = updateForm(formData)
  }

  try {
    const result = await editTicket(formData)

    if (result?.ticketUpdate?.ticket) {
      notify({
        type: NotificationTypes.Success,
        message: __('Ticket updated successfully.'),
      })

      // Reset article form after ticket update and reseted form.
      return () => {
        newTicketArticlePresent.value = false
      }
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

const canUpdateTicket = computed(() => !!ticket.value?.policy.update)

const updateFormLocation = (newLocation: string) => {
  formLocation.value = newLocation
}

const isFormValid = computed(() => {
  if (!newTicketArticlePresent.value) return isTicketFormGroupValid.value
  return isTicketFormGroupValid.value && isArticleFormGroupValid.value
})

const showArticleReplyDialog = () => {
  return openArticleReplyDialog({ updateFormLocation })
}

const { liveUserList } = useTicketLiveUser(ticket, isTicketAgent, isDirty)

provide<TicketInformation>(TICKET_INFORMATION_SYMBOL, {
  ticketQuery,
  initialFormTicketValue: initialTicketValue,
  ticket,
  form,
  newTicketArticleRequested,
  newTicketArticlePresent,
  updateFormLocation,
  canSubmitForm: canSubmit,
  canUpdateTicket,
  isFormValid,
  isTicketFormGroupValid,
  isArticleFormGroupValid,
  formSubmit,
  showArticleReplyDialog,
  liveUserList,
})

const { waitForConfirmation } = useConfirmation()

onBeforeRouteLeave(async () => {
  if (!isDirty.value) return true

  const confirmed = await waitForConfirmation(
    __('Are you sure? You have unsaved changes that will get lost.'),
  )

  return confirmed
})

const application = useApplicationStore()

const smimeIntegration = computed(
  () => (application.config.smime_integration as boolean) ?? false,
)

const ticketEditSchemaData = reactive({
  formLocation,
  smimeIntegration,
  newTicketArticleRequested,
  newTicketArticlePresent,
  currentArticleType,
})
</script>

<template>
  <RouterView />
  <!-- submit form is always present in the DOM, so we can access FormKit validity state -->
  <!-- if it's visible, it's moved to the [data-ticket-edit-form] element, which is in TicketInformationDetail -->
  <Teleport v-if="canUpdateTicket" :to="formLocation">
    <CommonLoader
      :class="formVisible ? 'visible' : 'hidden'"
      :loading="!ticket"
    >
      <Form
        v-if="ticket?.id && initialTicketValue"
        id="form-ticket-edit"
        :key="ticket.id"
        ref="form"
        :schema="ticketEditSchema"
        :flatten-form-groups="['ticket']"
        :handlers="[articleTypeHandler()]"
        :form-kit-plugins="[articleTypeSelectHandler]"
        :schema-data="ticketEditSchemaData"
        :initial-values="initialTicketValue"
        :initial-entity-object="ticket"
        :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketEdit"
        use-object-attributes
        :aria-hidden="!formVisible"
        :class="formVisible ? 'visible' : 'hidden'"
        @submit="submitForm($event as FormData)"
      />
    </CommonLoader>
  </Teleport>
</template>
