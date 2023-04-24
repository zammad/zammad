<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, provide, ref, reactive } from 'vue'
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
import { useForm, type FormData } from '#shared/components/Form/index.ts'
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import type { TicketInformation } from '#mobile/entities/ticket/types.ts'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import useConfirmation from '#mobile/components/CommonConfirmation/composable.ts'
import { getOpenedDialogs } from '#shared/composables/useDialog.ts'
import { useOnlineNotificationSeen } from '#shared/composables/useOnlineNotificationSeen.ts'
import { useErrorHandler } from '#shared/errors/useErrorHandler.ts'
import { useCommonSelect } from '#mobile/components/CommonSelect/composable.ts'
import { useTicketEdit } from '../composable/useTicketEdit.ts'
import { TICKET_INFORMATION_SYMBOL } from '../composable/useTicketInformation.ts'
import { useTicketQuery } from '../graphql/queries/ticket.api.ts'
import { TicketUpdatesDocument } from '../graphql/subscriptions/ticketUpdates.api.ts'
import { useTicketArticleReply } from '../composable/useTicketArticleReply.ts'
import { useTicketEditForm } from '../composable/useTicketEditForm.ts'
import { useTicketLiveUser } from '../composable/useTicketLiveUser.ts'

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

const { form, canSubmit, isDirty, formSubmit } = useForm()

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

const saveTicketForm = async (formData: FormData) => {
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

      // Reset article form after ticket update and reseted form.
      return () => {
        newTicketArticlePresent.value = false
        closeArticleReplyDialog()
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

const { liveUserList } = useTicketLiveUser(ticket, isTicketAgent, isDirty)

const refetchingStatus = ref(false)
const updateRefetchingStatus = (status: boolean) => {
  refetchingStatus.value = status
}

const scrolledToBottom = ref(false)

onBeforeRouteUpdate((to, from) => {
  // reset if we opened another ticket from the same page (via ticket merge, for example)
  if (to.params.internalId !== from.params.internalId) {
    scrolledToBottom.value = false
  }
})

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
  updateRefetchingStatus,
})

useOnlineNotificationSeen(ticket)

const { waitForConfirmation } = useConfirmation()

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

const { isOpened: commonSelectOpened } = useCommonSelect()

// show banner only in "articles list", "ticket information" and "create article" views
const showSaveBanner = computed(() => {
  const dialogs = getOpenedDialogs()

  if (
    commonSelectOpened.value ||
    dialogs.size > 1 ||
    (dialogs.size === 1 && !articleReplyDialog.isOpened.value)
  )
    return false

  return canUpdateTicket.value && isDirty.value
})

const bannerClasses = computed(() => {
  // move "save" button up, when there is "add reply" button
  if (
    route.name === 'TicketDetailArticlesView' &&
    !articleReplyDialog.isOpened.value
  )
    return '-translate-y-12'

  return null
})

const bannerTransitionDuration = VITE_TEST_MODE ? 0 : { enter: 300, leave: 200 }
</script>

<template>
  <RouterView />
  <div
    class="transition-all"
    :class="{ 'pb-safe-12': needSpaceForSaveBanner }"
  ></div>
  <!-- submit form is always present in the DOM, so we can access FormKit validity state -->
  <!-- if it's visible, it's moved to the [data-ticket-edit-form] element, which is in TicketInformationDetail -->
  <Teleport v-if="canUpdateTicket" :to="formLocation">
    <CommonLoader
      :class="formVisible ? 'visible' : 'hidden'"
      :loading="!ticket"
    >
      <!-- TODO: Maybe we need not to initialize the form, when someone has only readonly access? -->
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
        @submit="saveTicketForm($event as FormData)"
      />
    </CommonLoader>
  </Teleport>
  <Teleport to="body">
    <Transition
      :duration="bannerTransitionDuration"
      enter-from-class="TransitionUnderScreen"
      enter-active-class="translate-y-0"
      enter-to-class="-translate-y-1/3"
      leave-from-class="-translate-y-1/3"
      leave-active-class="TransitionUnderScreen"
      leave-to-class="TransitionUnderScreen"
    >
      <div
        v-if="showSaveBanner"
        class="mb-safe fixed bottom-2 z-10 flex rounded-lg bg-gray-300 text-white transition ltr:left-2 ltr:right-2 rtl:left-2 rtl:right-2"
        :class="bannerClasses"
      >
        <div class="relative flex flex-1 items-center gap-2 p-1.5">
          <div class="flex-1 text-sm ltr:pl-1 rtl:pr-1">
            {{ $t('You have unsaved changes.') }}
          </div>
          <FormKit
            variant="submit"
            input-class="font-semibold text-base px-4 py-1 !text-black formkit-variant-primary:bg-yellow rounded select-none"
            wrapper-class="flex justify-center items-center"
            type="button"
            form="form-ticket-edit"
            @click.prevent="submitForm"
          >
            {{ $t('Save') }}
          </FormKit>
          <div
            v-if="canSubmit && !isFormValid"
            role="status"
            :aria-label="$t('Validation failed')"
            class="absolute bottom-7 h-5 w-5 cursor-pointer rounded-full bg-red text-center text-xs leading-5 text-black ltr:right-2 rtl:left-2"
            @click="submitForm"
          >
            <CommonIcon
              class="mx-auto h-5"
              name="mobile-close"
              size="tiny"
              decorative
            />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.TransitionUnderScreen {
  transform: translateY(calc(100% + var(--safe-bottom)));
}
</style>
