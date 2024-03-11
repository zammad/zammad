<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, provide, ref, reactive, toRef } from 'vue'
import {
  onBeforeRouteLeave,
  onBeforeRouteUpdate,
  RouterView,
  useRoute,
  useRouter,
} from 'vue-router'
import { noop } from 'lodash-es'
import type {
  TicketUpdatesSubscription,
  TicketUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { EnumFormUpdaterId } from '#shared/graphql/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import type { TicketInformation } from '#mobile/entities/ticket/types.ts'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import { useOnlineNotificationSeen } from '#shared/composables/useOnlineNotificationSeen.ts'
import { useErrorHandler } from '#shared/errors/useErrorHandler.ts'
import { getOpenedDialogs } from '#shared/composables/useDialog.ts'
import { useCommonSelect } from '#mobile/components/CommonSelect/useCommonSelect.ts'
import { waitForConfirmation } from '#shared/utils/confirmation.ts'
import { useTicketEdit } from '../composable/useTicketEdit.ts'
import { TICKET_INFORMATION_SYMBOL } from '../composable/useTicketInformation.ts'
import { useTicketQuery } from '../graphql/queries/ticket.api.ts'
import { TicketUpdatesDocument } from '../graphql/subscriptions/ticketUpdates.api.ts'
import { useTicketArticleReply } from '../composable/useTicketArticleReply.ts'
import { useTicketEditForm } from '../composable/useTicketEditForm.ts'
import { useTicketLiveUser } from '../composable/useTicketLiveUser.ts'
import TicketDetailViewActions from '../components/TicketDetailView/TicketDetailViewActions.vue'

interface Props {
  internalId: string
}

const props = defineProps<Props>()
const ticketId = computed(() => convertToGraphQLId('Ticket', props.internalId))

const MENTIONS_LIMIT = 5

const { createQueryErrorHandler } = useErrorHandler()

const ticketQuery = new QueryHandler(
  useTicketQuery(() => ({
    ticketId: ticketId.value,
    mentionsCount: MENTIONS_LIMIT,
  })),
  {
    errorCallback: createQueryErrorHandler({
      notFound: __(
        'Ticket with specified ID was not found. Try checking the URL for errors.',
      ),
      forbidden: __('You have insufficient rights to view this ticket.'),
    }),
  },
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

const { form, canSubmit, isDirty, formSubmit, formReset } = useForm()

const { initialTicketValue, isTicketFormGroupValid, editTicket } =
  useTicketEdit(ticket, form)

const canUpdateTicket = computed(() => !!ticket.value?.policy.update)

const needSpaceForSaveBanner = computed(() => {
  return canUpdateTicket.value && isDirty.value
})

const {
  articleReplyDialog,
  newTicketArticleRequested,
  newTicketArticlePresent,
  isArticleFormGroupValid,
  openArticleReplyDialog,
  closeArticleReplyDialog,
} = useTicketArticleReply(ticket, form, needSpaceForSaveBanner)

const {
  currentArticleType,
  ticketEditSchema,
  articleTypeHandler,
  articleTypeSelectHandler,
} = useTicketEditForm(ticket)

const { isTicketAgent } = useTicketView(ticket)

const { notify } = useNotifications()

const saveTicketForm = async (formData: FormSubmitData) => {
  const updateFormData = currentArticleType.value?.updateForm
  if (updateFormData) {
    formData = updateFormData(formData)
  }
  try {
    const result = await editTicket(formData)

    if (result?.ticketUpdate?.ticket) {
      notify({
        type: NotificationTypes.Success,
        message: __('Ticket updated successfully.'),
      })

      // Reset article form after ticket update and reset form.
      return () => {
        newTicketArticlePresent.value = false
        closeArticleReplyDialog().then(() => {
          // after the dialog is closed, form changes value from reseted { ticket, article } to { ticket }
          // which makes it dirty, so we reset it again to be just { ticket }
          formReset({ ticket: formData.ticket })
        })
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

const { liveUserList } = useTicketLiveUser(
  toRef(() => props.internalId),
  isTicketAgent,
  isDirty,
)

const refetchingStatus = ref(false)
const updateRefetchingStatus = (status: boolean) => {
  refetchingStatus.value = status
}

const scrolledToBottom = ref(false)
const scrollDownState = ref(false)

onBeforeRouteUpdate((to, from) => {
  // reset if we opened another ticket from the same page (via ticket merge, for example)
  if (to.params.internalId !== from.params.internalId) {
    scrolledToBottom.value = false
  }

  scrollDownState.value = false
})

const newArticlesIds = reactive(new Set<string>())

provide<TicketInformation>(TICKET_INFORMATION_SYMBOL, {
  ticketQuery,
  initialFormTicketValue: initialTicketValue,
  ticket,
  form,
  scrolledToBottom,
  newTicketArticleRequested,
  newTicketArticlePresent,
  updateFormLocation,
  canUpdateTicket,
  showArticleReplyDialog,
  liveUserList,
  refetchingStatus,
  newArticlesIds,
  scrollDownState,
  updateRefetchingStatus,
})

useOnlineNotificationSeen(ticket)

onBeforeRouteLeave(async () => {
  if (!isDirty.value) return true

  const confirmed = await waitForConfirmation(
    __('Are you sure? You have unsaved changes that will get lost.'),
    {
      buttonTitle: __('Discard changes'),
      buttonVariant: 'danger',
    },
  )

  return confirmed
})

const router = useRouter()
const route = useRoute()

const submitForm = () => {
  if (!isTicketFormGroupValid.value && route.name !== 'Edit') {
    if (articleReplyDialog.isOpened.value) {
      closeArticleReplyDialog(true)
    }
    router.push(`/tickets/${ticket.value?.internalId}/information`)
  } else if (
    newTicketArticlePresent.value &&
    !isArticleFormGroupValid.value &&
    !articleReplyDialog.isOpened.value
  ) {
    showArticleReplyDialog()
  }

  formSubmit()
}

const application = useApplicationStore()

const securityIntegration = computed<boolean>(
  () =>
    (application.config.smime_integration ||
      application.config.pgp_integration) ??
    false,
)

const ticketEditSchemaData = reactive({
  formLocation,
  securityIntegration,
  newTicketArticleRequested,
  newTicketArticlePresent,
  currentArticleType,
})

const { isOpened: commonSelectOpened } = useCommonSelect()

const showReplyButton = computed(() => {
  if (articleReplyDialog.isOpened.value) return false

  return canUpdateTicket.value
})

const showScrollDown = computed(() => {
  if (articleReplyDialog.isOpened.value) return false

  return scrollDownState.value
})

// show banner only in "articles list", "ticket information" and "create article" views
const showBottomBanner = computed(() => {
  const dialogs = getOpenedDialogs()

  if (
    commonSelectOpened.value ||
    dialogs.size > 1 ||
    (dialogs.size === 1 && !articleReplyDialog.isOpened.value)
  )
    return false

  return (
    (canUpdateTicket.value && isDirty.value) ||
    showReplyButton.value ||
    showScrollDown.value
  )
})
</script>

<template>
  <RouterView />
  <div class="pb-safe-16"></div>
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
        @submit="saveTicketForm($event as FormSubmitData)"
      />
    </CommonLoader>
  </Teleport>
  <Teleport v-if="form?.formNode" to="body">
    <TicketDetailViewActions
      :form-invalid="canSubmit && !isFormValid"
      :new-replies-count="newArticlesIds.size"
      :new-article-present="newTicketArticlePresent"
      :can-reply="showReplyButton"
      :can-save="canUpdateTicket && isDirty"
      :can-scroll-down="showScrollDown"
      :hidden="!showBottomBanner"
      @reply="showArticleReplyDialog"
      @save="submitForm"
    />
  </Teleport>
</template>
