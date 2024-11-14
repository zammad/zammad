<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useLocalStorage } from '@vueuse/core'
import { cloneDeep } from 'lodash-es'
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
  useTemplateRef,
  ref,
} from 'vue'

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
import { setErrors } from '#shared/components/Form/utils.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import {
  useTicketMacros,
  macroScreenBehaviourMapping,
} from '#shared/entities/macro/composables/useMacros.ts'
import { useTicketArticleReplyAction } from '#shared/entities/ticket/composables/useTicketArticleReplyAction.ts'
import { useTicketEdit } from '#shared/entities/ticket/composables/useTicketEdit.ts'
import { useTicketEditForm } from '#shared/entities/ticket/composables/useTicketEditForm.ts'
import { useTicketLiveUserList } from '#shared/entities/ticket/composables/useTicketLiveUserList.ts'
import type {
  TicketArticleTimeAccountingFormData,
  TicketUpdateFormData,
} from '#shared/entities/ticket/types.ts'
import type { AppSpecificTicketArticleType } from '#shared/entities/ticket-article/action/plugins/types.ts'
import {
  useArticleDataHandler,
  type AddArticleCallbackArgs,
} from '#shared/entities/ticket-article/composables/useArticleDataHandler.ts'
import UserError from '#shared/errors/UserError.ts'
import {
  EnumTaskbarEntity,
  EnumFormUpdaterId,
  EnumTaskbarApp,
  EnumUserErrorException,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import { useTaskbarTabStateUpdates } from '#desktop/entities/user/current/composables/useTaskbarTabStateUpdates.ts'
import TicketDetailBottomBar from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailBottomBar/TicketDetailBottomBar.vue'
import { useTicketScreenBehavior } from '#desktop/pages/ticket/components/TicketDetailView/TicketScreenBehavior/useTicketScreenBehavior.ts'
import { useArticleContainerScroll } from '#desktop/pages/ticket/components/TicketDetailView/useArticleContainerScroll.ts'

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

const internalId = toRef(props, 'internalId')

const { ticket, ticketId, ...ticketInformation } =
  initializeTicketInformation(internalId)

const onAddArticleCallback = ({ articlesQuery }: AddArticleCallbackArgs) => {
  return (articlesQuery as QueryHandler).refetch()
}

const { articleResult, articlesQuery, isLoadingArticles } =
  useArticleDataHandler(ticketId, { pageSize: 20, onAddArticleCallback })

provide(ARTICLES_INFORMATION_KEY, {
  articles: computed(() => articleResult.value),
  articlesQuery,
})

const {
  form,
  values,
  flags,
  isDisabled,
  isDirty,
  isInitialSettled,
  formReset,
  formSubmit,
  triggerFormUpdater,
} = useForm()

const contentContainerElement = useTemplateRef('content-container')

const scrollToArticlesEnd = () => {
  nextTick(() => {
    const scrollHeight = contentContainerElement.value?.scrollHeight
    if (scrollHeight)
      contentContainerElement.value?.scrollTo({
        top: scrollHeight,
      })
  })
}

const groupId = computed(() =>
  isInitialSettled.value && values.value.group_id
    ? convertToGraphQLId('Group', values.value.group_id as number)
    : undefined,
)

const { setSkipNextStateUpdate } = useTaskbarTabStateUpdates(triggerFormUpdater)

const {
  ticketSchema,
  articleSchema,
  currentArticleType,
  ticketArticleTypes,
  securityIntegration,
  isTicketAgent,
  isTicketCustomer,
  isTicketEditable,
  articleTypeHandler,
  articleTypeSelectHandler,
} = useTicketEditForm(ticket, form)

const sidebarContext = computed<TicketSidebarContext>(() => ({
  ticket,
  isTicketEditable,
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

const hasInternalArticle = computed(
  () => (values.value as TicketUpdateFormData).article?.internal,
)

const formEditAttributeLocation = computed(() => {
  if (activeSidebar.value === 'information') return '#ticketEditAttributeForm'
  return '#wrapper-form-ticket-edit'
})

const {
  isArticleFormGroupValid,
  newTicketArticlePresent,
  showTicketArticleReplyForm,
} = useTicketArticleReply(form, activeTaskbarTabNewArticlePresent)

const { liveUserList } = useTicketLiveUserList(
  internalId,
  isTicketAgent,
  EnumTaskbarApp.Desktop,
)

provideTicketInformation({
  ticket,
  ticketId,
  isTicketEditable,
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

const { handleScreenBehavior } = useTicketScreenBehavior()

const canUseDraft = computed(() => {
  return flags.value.hasSharedDraft
})

const hasAvailableDraft = computed(() => {
  const sharedDraftZoomId = ticket.value?.sharedDraftZoomId
  if (!sharedDraftZoomId) return false

  return canUseDraft.value
})

const discardChanges = async () => {
  const confirm = await waitForVariantConfirmation('unsaved')

  if (confirm) {
    newTicketArticlePresent.value = false

    await nextTick()

    // Skip subscription for the current tab, to avoid not needed form updater requests.
    setSkipNextStateUpdate(true)

    formReset()
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

const { userId } = useSessionStore()

const articleReplyPinned = useLocalStorage(
  `${userId}-article-reply-pinned`,
  false,
)

const checkSubmitEditTicket = () => {
  if (!isFormValid.value) {
    if (activeSidebar.value !== 'information') switchSidebar('information')

    if (
      newTicketArticlePresent.value &&
      !isArticleFormGroupValid.value &&
      !articleReplyPinned.value
    )
      scrollToArticlesEnd()
  }

  formSubmit()
}

const skipValidators = ref<EnumUserErrorException[]>([])

const handleIncompleteChecklist = async (error: UserError) => {
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
    const exception = error.getFirstErrorException()
    if (exception) skipValidators.value?.push(exception)
    formSubmit()
    return true
  }

  return false
}

const timeAccountingData = ref<TicketArticleTimeAccountingFormData>()

const timeAccountingFlyout = useFlyout({
  name: 'ticket-time-accounting',
  component: () =>
    import('../components/TicketDetailView/TimeAccountingFlyout.vue'),
})

const handleTimeAccounting = (error: UserError) => {
  timeAccountingFlyout.open({
    onAccountTime: (data: TicketArticleTimeAccountingFormData) => {
      timeAccountingData.value = data
      formSubmit()
    },
    onSkip: () => {
      const exception = error.getFirstErrorException()
      if (exception) skipValidators.value?.push(exception)
      formSubmit()
    },
  })

  return false
}

const handleUserErrorException = (error: UserError) => {
  if (
    error.getFirstErrorException() ===
    EnumUserErrorException.ServiceTicketUpdateValidatorChecklistCompletedError
  )
    return handleIncompleteChecklist(error)

  if (
    error.getFirstErrorException() ===
    EnumUserErrorException.ServiceTicketUpdateValidatorTimeAccountingError
  )
    return handleTimeAccounting(error)

  return true
}

const { activeMacro, executeMacro, disposeActiveMacro } =
  useTicketMacros(formSubmit)

const submitEditTicket = async (
  formData: FormSubmitData<TicketUpdateFormData>,
) => {
  let data = cloneDeep(formData)
  if (currentArticleType.value?.updateForm)
    data = currentArticleType.value.updateForm(data)

  if (data.article && timeAccountingData.value) {
    data.article = {
      ...data.article,
      timeUnit:
        timeAccountingData.value.time_unit !== undefined
          ? parseFloat(timeAccountingData.value.time_unit)
          : undefined,
      accountedTimeTypeId: timeAccountingData.value.accounted_time_type_id
        ? convertToGraphQLId(
            'Ticket::TimeAccounting::Type',
            timeAccountingData.value.accounted_time_type_id,
          )
        : undefined,
    }
  }

  return editTicket(data, {
    macroId: activeMacro.value?.id,
    skipValidators: skipValidators.value,
  })
    .then((result) => {
      if (result?.ticketUpdate?.ticket) {
        notify({
          id: 'ticket-update',
          type: NotificationTypes.Success,
          message: __('Ticket updated successfully.'),
        })

        const screenBehaviour = activeMacro.value
          ? macroScreenBehaviourMapping[activeMacro.value?.uxFlowNextUp]
          : undefined

        handleScreenBehavior({
          screenBehaviour,
          ticket: result.ticketUpdate.ticket,
        })

        skipValidators.value.length = 0
        timeAccountingData.value = undefined

        // Await subscription to update article list before we scroll to the bottom.
        watch(articleResult, scrollToArticlesEnd, {
          once: true,
        })

        // Reset article form after ticket update and reset form.
        newTicketArticlePresent.value = false

        return {
          reset: (
            values: FormSubmitData<TicketUpdateFormData>,
            formNodeValues: FormValues,
          ) => {
            nextTick(() => {
              if (!formNodeValues) return
              formReset({ values: { ticket: formNodeValues.ticket } })
            })
          },
        }
      }

      return false
    })
    .catch((error) => {
      if (error instanceof UserError) {
        if (error.getFirstErrorException())
          return handleUserErrorException(error)
        skipValidators.value.length = 0
        timeAccountingData.value = undefined
        if (form.value?.formNode) {
          setErrors(form.value.formNode, error)
          return
        }
      }

      skipValidators.value.length = 0
      timeAccountingData.value = undefined

      notify({
        id: 'ticket-update-failed',
        type: NotificationTypes.Error,
        message: __('Ticket update failed.'),
      })
    })
    .finally(() => {
      disposeActiveMacro()
    })
}

const discardReplyForm = async () => {
  const confirm = await waitForVariantConfirmation('unsaved')

  if (!confirm) return

  newTicketArticlePresent.value = false

  await nextTick()

  // Skip subscription for the current tab, to avoid not needed form updater requests.
  setSkipNextStateUpdate(true)

  return triggerFormUpdater()
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
  initialTicketValue.value = undefined
  newTicketArticlePresent.value = undefined
})

const articleListInstance = useTemplateRef('article-list')
const topBarInstance = useTemplateRef('top-bar')

const {
  handleScroll,
  isHoveringOnTopBar,
  isHidingTicketDetails,
  isReachingBottom,
} = useArticleContainerScroll(
  ticket,
  contentContainerElement,
  articleListInstance,
  topBarInstance,
)
</script>

<template>
  <LayoutContent
    name="ticket-detail"
    no-padding
    background-variant="primary"
    :show-sidebar="hasSidebar"
    content-alignment="center"
    no-scrollable
  >
    <CommonLoader class="mt-8" :loading="!ticket">
      <div
        ref="content-container"
        class="relative grid h-full w-full overflow-y-auto"
        :class="{
          'grid-rows-[max-content_max-content_max-content]':
            !newTicketArticlePresent || !articleReplyPinned,
          'grid-rows-[max-content_1fr_max-content]':
            newTicketArticlePresent && articleReplyPinned,
        }"
        @scroll.passive="handleScroll"
      >
        <div class="sticky top-0 z-10">
          <TicketDetailTopBar
            :key="`${isHidingTicketDetails}-ticket-detail-top-bar`"
            ref="top-bar"
            class="invisible"
            aria-hidden="true"
            data-test-id="invisible-ticket-detail-top-bar"
            :hide-details="false"
          />
          <Transition name="slide-down">
            <TicketDetailTopBar
              :key="`${isHidingTicketDetails}-top-bar`"
              v-model:hover="isHoveringOnTopBar"
              data-test-id="visible-ticket-detail-top-bar"
              class="absolute left-0 right-0 top-0 w-full"
              :hide-details="isHidingTicketDetails"
            />
          </Transition>
        </div>

        <ArticleList ref="article-list" :aria-busy="isLoadingArticles" />

        <ArticleReply
          v-if="ticket?.id && isTicketEditable"
          :ticket="ticket"
          :new-article-present="newTicketArticlePresent"
          :create-article-type="ticket.createArticleType?.name"
          :ticket-article-types="ticketArticleTypes"
          :is-ticket-customer="isTicketCustomer"
          :has-internal-article="hasInternalArticle"
          :parent-reached-bottom-scroll="isReachingBottom"
          @show-article-form="handleShowArticleForm"
          @discard-form="discardReplyForm"
        />

        <div id="wrapper-form-ticket-edit" class="hidden" aria-hidden="true">
          <Form
            v-if="ticket?.id && initialTicketValue"
            id="form-ticket-edit"
            :key="ticket.id"
            ref="form"
            :form-id="activeTaskbarTabFormId"
            :schema="ticketEditSchema"
            :disabled="!isTicketEditable"
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
            @submit="
              submitEditTicket($event as FormSubmitData<TicketUpdateFormData>)
            "
            @settled="onEditFormSettled"
            @changed="setSkipNextStateUpdate(true)"
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
      <TicketDetailBottomBar
        :can-use-draft="canUseDraft"
        :dirty="isDirty"
        :disabled="isDisabled"
        :form="form"
        :group-id="groupId"
        :is-ticket-agent="isTicketAgent"
        :is-ticket-editable="isTicketEditable"
        :has-available-draft="hasAvailableDraft"
        :live-user-list="liveUserList"
        :shared-draft-id="ticket?.sharedDraftZoomId"
        :ticket-id="ticketId"
        @submit="checkSubmitEditTicket"
        @discard="discardChanges"
        @execute-macro="executeMacro"
      />
    </template>
  </LayoutContent>
</template>
