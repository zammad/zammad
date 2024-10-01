<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { cloneDeep, noop } from 'lodash-es'
import { computed, provide, ref, reactive, toRef, nextTick } from 'vue'
import {
  onBeforeRouteLeave,
  onBeforeRouteUpdate,
  RouterView,
  useRoute,
  useRouter,
} from 'vue-router'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSubmitData,
  FormValues,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useOnlineNotificationSeen } from '#shared/composables/useOnlineNotificationSeen.ts'
import { useTicketEdit } from '#shared/entities/ticket/composables/useTicketEdit.ts'
import { useTicketEditForm } from '#shared/entities/ticket/composables/useTicketEditForm.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { TicketUpdatesDocument } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.api.ts'
import type { TicketUpdateFormData } from '#shared/entities/ticket/types.ts'
import { useErrorHandler } from '#shared/errors/useErrorHandler.ts'
import UserError from '#shared/errors/UserError.ts'
import type {
  TicketUpdatesSubscription,
  TicketUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import {
  EnumFormUpdaterId,
  EnumUserErrorException,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import { useCommonSelect } from '#mobile/components/CommonSelect/useCommonSelect.ts'
import { getOpenedDialogs } from '#mobile/composables/useDialog.ts'
import { useTicketWithMentionLimitQuery } from '#mobile/entities/ticket/graphql/queries/ticketWithMentionLimit.api.ts'
import type { TicketInformation } from '#mobile/entities/ticket/types.ts'

import TicketDetailViewActions from '../components/TicketDetailView/TicketDetailViewActions.vue'
import { useTicketArticleReply } from '../composable/useTicketArticleReply.ts'
import { TICKET_INFORMATION_SYMBOL } from '../composable/useTicketInformation.ts'
import { useTicketLiveUser } from '../composable/useTicketLiveUser.ts'

interface Props {
  internalId: string
}

const props = defineProps<Props>()
const ticketId = computed(() => convertToGraphQLId('Ticket', props.internalId))

const MENTIONS_LIMIT = 5

const { createQueryErrorHandler } = useErrorHandler()

const ticketQuery = new QueryHandler(
  useTicketWithMentionLimitQuery(() => ({
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

const {
  currentArticleType,
  ticketSchema,
  articleSchema,
  securityIntegration,
  isTicketEditable,
  articleTypeHandler,
  articleTypeSelectHandler,
} = useTicketEditForm(ticket, form)

const needSpaceForSaveBanner = computed(
  () => isTicketEditable.value && isDirty.value,
)

const {
  articleReplyDialog,
  newTicketArticleRequested,
  newTicketArticlePresent,
  isArticleFormGroupValid,
  openArticleReplyDialog,
  closeArticleReplyDialog,
} = useTicketArticleReply(ticket, form, needSpaceForSaveBanner)

const ticketEditSchema = [
  {
    isLayout: true,
    component: 'FormGroup',
    props: {
      style: {
        if: '$formLocation !== "[data-ticket-edit-form]"',
        then: 'display: none;',
      },
      showDirtyMark: true,
    },
    children: [ticketSchema],
  },
  {
    isLayout: true,
    component: 'FormGroup',
    props: {
      style: {
        if: '$formLocation !== "[data-ticket-article-reply-form]"',
        then: 'display: none;',
      },
    },
    children: [articleSchema],
  },
]

const { isTicketAgent } = useTicketView(ticket)

const { notify } = useNotifications()

const saveTicketForm = async (
  formData: FormSubmitData<TicketUpdateFormData>,
) => {
  let data = cloneDeep(formData)

  if (currentArticleType.value?.updateForm)
    data = currentArticleType.value.updateForm(formData)

  try {
    const result = await editTicket(
      data,
      { skipValidators: Object.values(EnumUserErrorException) }, // skip all validators, they are irrelevant for mobile view
    )

    if (result?.ticketUpdate?.ticket) {
      notify({
        id: 'ticket-update',
        type: NotificationTypes.Success,
        message: __('Ticket updated successfully.'),
      })

      // Reset article form after ticket update and reset form.
      newTicketArticlePresent.value = false

      return {
        reset: (
          values: FormSubmitData<TicketUpdateFormData>,
          formNodeValues: FormValues,
        ) => {
          nextTick(() => {
            closeArticleReplyDialog().then(() => {
              formReset({ values: { ticket: formNodeValues.ticket } })
            })
          })
        },
      }
    }
  } catch (errors) {
    if (errors instanceof UserError) {
      notify({
        id: 'ticket-update-error',
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
  isTicketEditable,
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

  const { waitForConfirmation } = useConfirmation()

  const confirmed = await waitForConfirmation(
    __('Are you sure? You have unsaved changes that will get lost.'),
    {
      buttonLabel: __('Discard changes'),
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

  return isTicketEditable.value
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
    (isTicketEditable.value && isDirty.value) ||
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
  <Teleport v-if="isTicketEditable" :to="formLocation">
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
        @submit="saveTicketForm($event as FormSubmitData<TicketUpdateFormData>)"
      />
    </CommonLoader>
  </Teleport>
  <Teleport v-if="form?.formNode" to="body">
    <TicketDetailViewActions
      :form-invalid="canSubmit && !isFormValid"
      :new-replies-count="newArticlesIds.size"
      :new-article-present="newTicketArticlePresent"
      :can-reply="showReplyButton"
      :can-save="isTicketEditable && isDirty"
      :can-scroll-down="showScrollDown"
      :hidden="!showBottomBanner"
      @reply="showArticleReplyDialog"
      @save="submitForm"
    />
  </Teleport>
</template>
