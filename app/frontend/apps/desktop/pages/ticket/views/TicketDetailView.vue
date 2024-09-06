<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useLocalStorage } from '@vueuse/core'
import {
  computed,
  toRef,
  provide,
  Teleport,
  markRaw,
  type Component,
  reactive,
  nextTick,
  watch,
  ref,
} from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { setErrors } from '#shared/components/Form/utils.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTicketArticleReplyAction } from '#shared/entities/ticket/composables/useTicketArticleReplyAction.ts'
import { useTicketEdit } from '#shared/entities/ticket/composables/useTicketEdit.ts'
import { useTicketEditForm } from '#shared/entities/ticket/composables/useTicketEditForm.ts'
import type { TicketFormData } from '#shared/entities/ticket/types.ts'
import type { AppSpecificTicketArticleType } from '#shared/entities/ticket-article/action/plugins/types.ts'
import {
  useArticleDataHandler,
  type AddArticleCallbackArgs,
} from '#shared/entities/ticket-article/composables/useArticleDataHandler.ts'
import UserError from '#shared/errors/UserError.ts'
import { EnumTaskbarEntity, EnumFormUpdaterId } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'

import ArticleList from '../components/TicketDetailView/ArticleList.vue'
import ArticleReply from '../components/TicketDetailView/ArticleReply.vue'
import TicketDetailTopBar from '../components/TicketDetailView/TicketDetailTopBar/TicketDetailTopBar.vue'
import TicketSidebar from '../components/TicketSidebar.vue'
import { ARTICLES_INFORMATION_KEY } from '../composables/useArticleContext.ts'
import { useTicketArticleReply } from '../composables/useTicketArticleReply.ts'
import {
  initializeTicketInformation,
  provideTicketInformation,
} from '../composables/useTicketInformation.ts'
import {
  useTicketSidebar,
  useProvideTicketSidebar,
} from '../composables/useTicketSidebar.ts'
import {
  type TicketSidebarContext,
  TicketSidebarScreenType,
} from '../types/sidebar.ts'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

const {
  activeTaskbarTab,
  activeTaskbarTabFormId,
  activeTaskbarTabNewArticlePresent,
} = useTaskbarTab(EnumTaskbarEntity.TicketZoom)

const { ticket, ticketId, canUpdateTicket, ...ticketInformation } =
  initializeTicketInformation(toRef(props, 'internalId'))

const onAddArticleCallback = ({ articlesQuery }: AddArticleCallbackArgs) => {
  return (articlesQuery as QueryHandler).refetch()
}

const { articleResult, articlesQuery, isLoadingArticles } =
  useArticleDataHandler(ticketId, { pageSize: 20, onAddArticleCallback })

provide(ARTICLES_INFORMATION_KEY, {
  articles: computed(() => articleResult.value),
  articlesQuery,
})

const { form, flags, isDisabled, isDirty, formNodeId, formReset, formSubmit } =
  useForm()

const sidebarContext = computed<TicketSidebarContext>(() => ({
  screenType: TicketSidebarScreenType.TicketDetailView,
  form: form.value,
  formValues: {
    // TODO: Workaround, to make the sidebars working for now.
    customer_id: ticket.value?.customer.internalId,
    organization_id: ticket.value?.organization?.internalId,
  },
}))

useProvideTicketSidebar(sidebarContext)
const { hasSidebar, activeSidebar, switchSidebar } = useTicketSidebar()

const {
  ticketSchema,
  articleSchema,
  currentArticleType,
  ticketArticleTypes,
  securityIntegration,
  isTicketCustomer,
  articleTypeHandler,
  articleTypeSelectHandler,
} = useTicketEditForm(ticket, form)

const formEditAttributeLocation = computed(() => {
  if (activeSidebar.value === 'information') return '#ticketEditAttributeForm'
  return '#wrapper-form-ticket-edit'
})

const {
  isArticleFormGroupValid,
  newTicketArticlePresent,
  showTicketArticleReplyForm,
} = useTicketArticleReply(form, activeTaskbarTabNewArticlePresent)

provideTicketInformation({
  ticket,
  ticketId,
  canUpdateTicket,
  form,
  newTicketArticlePresent,
  showTicketArticleReplyForm,
  ...ticketInformation,
})

const ticketEditSchemaData = reactive({
  formEditAttributeLocation,
  securityIntegration,
  newTicketArticlePresent,
  currentArticleType,
})

const ticketEditSchema = [
  {
    isLayout: true,
    component: 'Teleport',
    props: {
      to: '$formEditAttributeLocation',
    },
    children: [
      {
        isLayout: true,
        component: 'FormGroup',
        props: {
          class: '@container/form-group',
          showDirtyMark: true,
        },
        children: [ticketSchema],
      },
    ],
  },
  {
    if: '$newTicketArticlePresent',
    isLayout: true,
    component: 'Teleport',
    props: {
      to: '#ticketArticleReplyForm',
    },
    children: [
      {
        isLayout: true,
        component: 'FormGroup',
        props: {
          class: '@container/form-group',
        },
        children: [articleSchema],
      },
    ],
  },
]

const { waitForConfirmation, waitForVariantConfirmation } = useConfirmation()

const discardChanges = async () => {
  const confirm = await waitForVariantConfirmation('unsaved')

  if (confirm) {
    newTicketArticlePresent.value = false

    nextTick(() => {
      formReset()
    })
  }
}

const { isTicketFormGroupValid, initialTicketValue, editTicket } =
  useTicketEdit(ticket, form)

const { openReplyForm } = useTicketArticleReplyAction(
  form,
  showTicketArticleReplyForm,
)

const isFormValid = computed(() => {
  if (!newTicketArticlePresent.value) return isTicketFormGroupValid.value

  return isTicketFormGroupValid.value && isArticleFormGroupValid.value
})

const formAdditionalRouteQueryParams = computed(() => ({
  taskbarId: activeTaskbarTab.value?.taskbarTabId,
}))

const { notify } = useNotifications()

const checkSubmitEditTicket = () => {
  if (!isFormValid.value) {
    if (activeSidebar.value !== 'information') switchSidebar('information')

    if (newTicketArticlePresent.value && !isArticleFormGroupValid.value) {
      document
        .querySelector('#ticketArticleReplyForm')
        ?.scrollIntoView({ behavior: 'smooth' })
    }

    return
  }

  formSubmit()
}

const skipValidator = ref<string>()

const handleIncompleteChecklist = async (validator: string) => {
  const confirmed = await waitForConfirmation(
    __(
      'You have unchecked items in the checklist. Do you want to handle them before closing this ticket?',
    ),
    {
      headerTitle: __('Incomplete Ticket Checklist'),
      headerIcon: 'checklist',
      buttonLabel: __('Yes, open the checklist'),
      cancelLabel: __('No, just close the ticket'),
    },
  )

  if (confirmed) {
    if (activeSidebar.value !== 'checklist') switchSidebar('checklist')
    return false
  }

  if (confirmed === false) {
    skipValidator.value = validator
    formSubmit()
    return true
  }

  return false
}

const handleUserErrorException = (exception: string) => {
  if (
    exception ===
    'Service::Ticket::Update::Validator::ChecklistCompleted::IncompleteChecklistError'
  )
    return handleIncompleteChecklist(exception)
}

const submitEditTicket = async (formData: FormSubmitData<TicketFormData>) => {
  const updateFormData = currentArticleType.value?.updateForm
  if (updateFormData) {
    formData = updateFormData(formData)
  }

  return editTicket(formData, skipValidator.value)
    .then((result) => {
      if (result?.ticketUpdate?.ticket) {
        notify({
          id: 'ticket-update',
          type: NotificationTypes.Success,
          message: __('Ticket updated successfully.'),
        })

        newTicketArticlePresent.value = false

        return true // will reset the ticket form, because of the reset inside the Form component
      }

      return false
    })
    .catch((error) => {
      if (error instanceof UserError) {
        const exception = error.getFirstErrorException()
        if (exception) return handleUserErrorException(exception)
        if (form.value?.formNode) {
          setErrors(form.value.formNode, error)
          return
        }
      }

      notify({
        id: 'ticket-update-failed',
        type: NotificationTypes.Error,
        message: __('Ticket update failed.'),
      })
    })
    .finally(() => {
      skipValidator.value = undefined
    })
}

const handleShowArticleForm = (
  articleType: string,
  performReply: AppSpecificTicketArticleType['performReply'],
) => {
  openReplyForm({ articleType, ...performReply?.(ticket.value) })
}

const onEditFormSettled = () => {
  watch(
    () => flags.value.newArticlePresent,
    (newValue) => {
      newTicketArticlePresent.value = newValue
    },
  )
}

// Reset newTicketArticlePresent when ticket changed, that the
// taskbar information is used for the start.
watch(ticketId, () => {
  newTicketArticlePresent.value = undefined
})

const { userId } = useSessionStore()

const articleReplyPinned = useLocalStorage(
  `${userId}-article-reply-pinned`,
  false,
)
</script>

<template>
  <LayoutContent
    name="ticket-detail"
    no-padding
    background-variant="primary"
    :show-sidebar="hasSidebar"
    content-alignment="center"
  >
    <CommonLoader class="mt-8" :loading="!ticket">
      <div
        class="grid h-full w-full"
        :class="{
          'grid-rows-[max-content_max-content_max-content]':
            !newTicketArticlePresent || !articleReplyPinned,
          'grid-rows-[max-content_1fr_max-content]':
            newTicketArticlePresent && articleReplyPinned,
        }"
      >
        <TicketDetailTopBar />
        <ArticleList :aria-busy="isLoadingArticles" />

        <ArticleReply
          v-if="ticket?.id"
          :ticket="ticket"
          :new-article-present="newTicketArticlePresent"
          :create-article-type="ticket.createArticleType?.name"
          :ticket-article-types="ticketArticleTypes"
          :is-ticket-customer="isTicketCustomer"
          @show-article-form="handleShowArticleForm"
        />

        <div id="wrapper-form-ticket-edit" class="hidden" aria-hidden="true">
          <Form
            v-if="ticket?.id && initialTicketValue"
            id="form-ticket-edit"
            :key="ticketId"
            ref="form"
            :form-id="activeTaskbarTabFormId"
            :schema="ticketEditSchema"
            :flatten-form-groups="['ticket']"
            :handlers="[articleTypeHandler()]"
            :form-kit-plugins="[articleTypeSelectHandler]"
            :schema-data="ticketEditSchemaData"
            :initial-values="initialTicketValue"
            :initial-entity-object="ticket"
            :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketEdit"
            :form-updater-additional-params="formAdditionalRouteQueryParams"
            use-object-attributes
            :schema-component-library="{
              Teleport: markRaw(Teleport) as unknown as Component,
            }"
            @submit="submitEditTicket($event as FormSubmitData<TicketFormData>)"
            @settled="onEditFormSettled"
          />
        </div>
      </div>
    </CommonLoader>
    <template #sideBar="{ isCollapsed, toggleCollapse }">
      <TicketSidebar
        :is-collapsed="isCollapsed"
        :toggle-collapse="toggleCollapse"
        :context="sidebarContext"
      />
    </template>
    <template #bottomBar>
      <CommonButton
        v-if="isDirty"
        size="large"
        variant="danger"
        :disabled="isDisabled"
        @click="discardChanges"
        >{{ __('Discard your unsaved changes') }}</CommonButton
      >
      <CommonButton
        size="large"
        variant="submit"
        type="button"
        :form="formNodeId"
        :disabled="isDisabled"
        @click="checkSubmitEditTicket"
        >{{ __('Update') }}</CommonButton
      >
    </template>
  </LayoutContent>
</template>
