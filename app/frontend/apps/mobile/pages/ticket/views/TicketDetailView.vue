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
import type UserError from '@shared/errors/UserError'
import { QueryHandler } from '@shared/server/apollo/handler'
import { ErrorStatusCodes } from '@shared/types/error'
import Form from '@shared/components/Form/Form.vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { useForm, FormData } from '@shared/components/Form'
import { computed, provide, ref, reactive } from 'vue'
import { noop } from 'lodash-es'
import { onBeforeRouteLeave, RouterView, useRouter, useRoute } from 'vue-router'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import useConfirmation from '@mobile/components/CommonConfirmation/composable'
import { convertToGraphQLId } from '@shared/graphql/utils'
import { useDialog } from '@shared/composables/useDialog'
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
const formLocation = ref('body')
const formVisible = computed(() => formLocation.value !== 'body')

const router = useRouter()
const route = useRoute()

ticketQuery.onError(() => {
  return redirectToError(router, {
    statusCode: ErrorStatusCodes.Forbidden,
    message: __('Sorry, but you have insufficient rights to open this page.'),
  })
})

const { form, canSubmit, isDirty, formSubmit } = useForm()

const {
  initialTicketValue,
  articleFormGroupNode,
  isTicketFormGroupValid,
  isArticleFormGroupValid,
  editTicket,
  newTicketArticleRequested,
  newTicketArticlePresent,
} = useTicketEdit(ticket, form)

const { notify } = useNotifications()

const submitForm = async (formData: FormData) => {
  // TODO: Maybe this can also be moved in the editTicket function?
  return editTicket(formData)
    .then((result) => {
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

      return null
    })
    .catch((errors: UserError) => {
      notify({
        message: errors.generalErrors[0],
        type: NotificationTypes.Error,
      })
    })
}

const canUpdateTicket = computed(() => !!ticket.value?.policy.update)

const updateFormLocation = (newLocation: string) => {
  formLocation.value = newLocation
}

const isFormValid = computed(() => {
  if (!newTicketArticlePresent.value) return isTicketFormGroupValid.value
  return isTicketFormGroupValid.value && isArticleFormGroupValid.value
})

const articleReplyDialog = useDialog({
  name: 'ticket-article-reply',
  component: () =>
    import(
      '@mobile/pages/ticket/components/TicketDetailView/ArticleReplyDialog.vue'
    ),
  beforeOpen: () => {
    newTicketArticleRequested.value = true
  },
  afterClose: () => {
    newTicketArticleRequested.value = false
  },
})

const showArticleReplyDialog = () => {
  if (!ticket.value) return

  articleReplyDialog.open({
    name: articleReplyDialog.name,
    ticket,
    form,
    newTicketArticlePresent,
    articleFormGroupNode,
    updateFormLocation,
    onDone() {
      newTicketArticlePresent.value = true
    },
    onDiscard() {
      newTicketArticlePresent.value = false
    },
    onShowArticleForm() {
      updateFormLocation('[data-ticket-article-reply-form]')
    },
    onHideArticleForm() {
      if (route.name === 'TicketInformationDetails') {
        updateFormLocation('[data-ticket-edit-form]')
        return
      }

      updateFormLocation('body')
    },
  })
}

provide(TICKET_INFORMATION_SYMBOL, {
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
      style: {
        if: '$formLocation !== "[data-ticket-edit-form]"',
        then: 'display: none;',
      },
      showDirtyMark: true,
    },
    children: [
      {
        type: 'group',
        name: 'ticket', // will be flattened in the form submit result
        isGroupOrList: true,
        children: [
          {
            name: 'title',
            type: 'text',
            label: __('Ticket title'),
            required: true, // TODO core workflow resets it (fix needed: https://github.com/zammad/zammad/issues/4415)
          },
          {
            screen: 'edit',
            object: EnumObjectManagerObjects.Ticket,
          },
        ],
      },
    ],
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
    children: [
      {
        if: '$newTicketArticleRequested || $newTicketArticlePresent',
        type: 'group',
        name: 'article',
        isGroupOrList: true,
        children: [
          {
            name: 'articleType',
            label: __('Article Type'),
            labelSrOnly: true,
            type: 'select',
            props: {
              // TODO: needs to be defined from the ticket article action layer
              options: [
                {
                  value: 'note',
                  label: __('Note'),
                  icon: 'mobile-note',
                },
                {
                  value: 'phone',
                  label: __('Phone'),
                  icon: 'mobile-phone',
                },
              ],
            },
            triggerFormUpdater: false,
          },
          {
            name: 'internal',
            label: __('Visibility'),
            labelSrOnly: true,
            type: 'select',
            props: {
              options: [
                {
                  value: true,
                  label: __('Internal'),
                  icon: 'mobile-lock',
                },
                {
                  value: false,
                  label: __('Public'),
                  icon: 'mobile-unlock',
                },
              ],
            },
            triggerFormUpdater: false,
          },
          {
            name: 'to',
            label: __('To'),
            type: 'recipient',
            props: {
              multiple: true,
            },
            triggerFormUpdater: false,
          },
          {
            name: 'cc',
            label: __('CC'),
            type: 'recipient',
            props: {
              multiple: true,
            },
            triggerFormUpdater: false,
          },
          {
            name: 'subject',
            label: __('Subject'),
            type: 'text',
            props: {
              maxlength: 200,
            },
            triggerFormUpdater: false,
          },
          {
            name: 'security',
            label: __('Security'),
            type: 'security',
            props: {
              // TODO ...
            },
            triggerFormUpdater: false,
          },
          {
            name: 'body',
            screen: 'edit',
            object: EnumObjectManagerObjects.TicketArticle,
            props: {
              meta: {
                mentionUser: {
                  groupNodeId: 'group_id',
                },
              },
            },
            triggerFormUpdater: false,
            required: true, // debug
          },
          {
            type: 'file',
            name: 'attachments',
            props: {
              multiple: true,
            },
          },
        ],
      },
    ],
  },
]

const ticketEditSchemaData = reactive({
  formLocation,
  newTicketArticleRequested,
  newTicketArticlePresent,
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
