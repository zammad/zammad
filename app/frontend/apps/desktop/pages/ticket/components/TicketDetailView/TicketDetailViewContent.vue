<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useScroll, whenever } from '@vueuse/core'
import { cloneDeep, isEqual } from 'lodash-es'
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
  effectScope,
  onUnmounted,
} from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData, FormValues } from '#shared/components/Form/types.ts'
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
import { useTicketNumberAndTitle } from '#shared/entities/ticket/composables/useTicketNumberAndTitle.ts'
import { useTicketSignature } from '#shared/entities/ticket/composables/useTicketSignature.ts'
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
import { EnumFormUpdaterId, EnumTaskbarApp, EnumUserErrorException } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { GraphQLErrorTypes, type GraphQLHandlerError } from '#shared/types/error.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonIndicator from '#desktop/components/CommonIndicator/CommonIndicator.vue'
import { useIndicator } from '#desktop/components/CommonIndicator/useIndicator.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { usePage } from '#desktop/composables/usePage.ts'
import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import { useTaskbarTabStateUpdates } from '#desktop/entities/user/current/composables/useTaskbarTabStateUpdates.ts'
import type { TaskbarTabContext } from '#desktop/entities/user/current/types.ts'
import TicketDetailBottomBar from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailBottomBar/TicketDetailBottomBar.vue'
import { items as highlightMenuItems } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/useHighlightMenuState.ts'
import { useTicketScreenBehavior } from '#desktop/pages/ticket/components/TicketDetailView/TicketScreenBehavior/useTicketScreenBehavior.ts'

import { ARTICLES_INFORMATION_KEY } from '../../composables/useArticleContext.ts'
import { useTicketArticleReply } from '../../composables/useTicketArticleReply.ts'
import {
  initializeTicketInformation,
  provideTicketInformation,
} from '../../composables/useTicketInformation.ts'
import { useTicketSidebar, useProvideTicketSidebar } from '../../composables/useTicketSidebar.ts'
import { type TicketSidebarContext, TicketSidebarScreenType } from '../../types/sidebar.ts'
import TicketSidebar from '../TicketSidebar.vue'

import ArticleList from './ArticleList.vue'
import ArticleReply from './ArticleReply.vue'
import TicketDetailTopBar from './TicketDetailTopBar/TicketDetailTopBar.vue'
import { useUnreadArticle } from './useUnreadArticle.ts'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

const internalId = toRef(props, 'internalId')
const isReplyPinned = ref(false)
const contentContainerElement = useTemplateRef('content-container')

const { ticket, ticketId, ...ticketInformation } = initializeTicketInformation(internalId)

const { isIntersecting: isReachingBottom } = useIndicator()
const { articleCount, addUnreadArticle } = useUnreadArticle({ cleanupDependency: isReachingBottom })

const onAddArticleCallback = ({ articlesQuery, updates }: AddArticleCallbackArgs) => {
  // When we are at the end user is aware of the new article
  if (!isReachingBottom.value) addUnreadArticle(updates?.addArticle?.id as string)

  return (articlesQuery as QueryHandler).refetch()
}

const { articleResult, articlesQuery, isLoadingArticles } = useArticleDataHandler(ticketId, {
  pageSize: 20,
  onAddArticleCallback,
})

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

const tabContext = computed<TaskbarTabContext>((currentContext) => {
  if (!isInitialSettled.value) return {}

  const newContext = {
    formIsDirty: isDirty.value,
  }

  if (currentContext && isEqual(newContext, currentContext)) return currentContext

  return newContext
})

const { currentTaskbarTabId, currentTaskbarTabFormId, currentTaskbarTabNewArticlePresent } =
  useTaskbarTab(tabContext)

const { ticketNumberWithTitle } = useTicketNumberAndTitle(ticket)

usePage({
  metaTitle: ticketNumberWithTitle,
})

const { scrollIntoView: scrollToArticle } = useScrollPosition(contentContainerElement)

const handleScrollToArticle = async (behavior: 'smooth' | 'instant' = 'instant') =>
  scrollToArticle('end', { behavior })

const isReplyActive = computed(() => !isLoadingArticles.value && isInitialSettled.value)

const ticketDetailTopBarInstance = useTemplateRef('detail-top-bar')

let scrollTimeout: NodeJS.Timeout | undefined
const scrollScope = effectScope()

const handleInitialScrollToEnd = () => {
  const stopWatch = watch(
    () => isReplyActive.value,
    (visible) => {
      if (!visible) return
      //  It is unreliable scrolling to the end
      // Async effects which need to run before
      // :TODO find a better solution then setTimeout
      scrollTimeout = setTimeout(() => {
        handleScrollToArticle('instant')

        scrollScope.run(() => {
          const { directions } = useScroll(contentContainerElement)

          // Wait for the user to initially scroll up
          // Because when this code has run, we are at the bottom
          whenever(
            () => directions.top,
            () => {
              ticketDetailTopBarInstance.value?.hideDetails()
              scrollScope.stop()
            },
          )
        })

        stopWatch()
      }, 50)
    },
    { flush: 'post', immediate: true },
  )
}

onUnmounted(() => {
  if (scrollTimeout) clearTimeout(scrollTimeout)
  scrollScope.stop()
})

const groupId = computed(() =>
  isInitialSettled.value && values.value.group_id
    ? convertToGraphQLId('Group', values.value.group_id as number)
    : undefined,
)

const {
  ticketSchema,
  articleSchema,
  currentArticleType,
  ticketArticleTypes,
  ticketArticleDefaultValues,
  securityIntegration,
  isTicketAgent,
  isTicketCustomer,
  isTicketEditable,
  articleTypeHandler,
  articleTypeSelectHandler,
} = useTicketEditForm(ticket, form)

const { signatureHandling } = useTicketSignature('email')

const {
  isArticleFormGroupValid,
  newTicketArticlePresent,
  articleFormGroupNode,
  showTicketArticleReplyForm,
} = useTicketArticleReply(form, currentTaskbarTabNewArticlePresent)

useTaskbarTabStateUpdates(currentTaskbarTabId, form, triggerFormUpdater, async () => {
  newTicketArticlePresent.value = false

  await nextTick()

  currentArticleType.value = undefined

  nextTick(() => {
    formReset({
      values: {
        article: ticketArticleDefaultValues,
      },
    })
  })
})

const sidebarContext = computed<TicketSidebarContext>(() => ({
  ticket,
  isTicketEditable,
  screenType: TicketSidebarScreenType.TicketDetailView,
  view: isTicketAgent.value ? 'agent' : 'customer',
  form: form.value,
  formValues: {
    // TODO: Workaround, to make the sidebars working for now.
    customer_id: ticket.value?.customer.internalId,
    organization_id: ticket.value?.organization?.internalId,
  },
  currentTaskbarTabId,
}))

useProvideTicketSidebar(sidebarContext)
const { hasSidebar, activeSidebar, switchSidebar } = useTicketSidebar()

const hasInternalArticle = computed(() => (values.value as TicketUpdateFormData).article?.internal)

const formEditAttributeLocation = computed(() => {
  if (activeSidebar.value === 'information') return '#ticketEditAttributeForm'
  return '#wrapper-form-ticket-edit'
})

const formArticleReplyLocation = computed(() => {
  if (newTicketArticlePresent.value) return '#ticketArticleReplyForm'
  return '#wrapper-form-ticket-edit'
})

const hiddenFormGroups = computed(() => {
  if (newTicketArticlePresent.value) return

  return ['article']
})

const { liveUserList } = useTicketLiveUserList(internalId, isTicketAgent, EnumTaskbarApp.Desktop)

provideTicketInformation({
  ticket,
  ticketId,
  isTicketEditable,
  form,
  newTicketArticlePresent,
  showTicketArticleReplyForm,
  highlightMenu: reactive({
    activeMenuItem: highlightMenuItems[0],
    isActive: false,
    isEraserActive: false,
  }),
  ...ticketInformation,
})

const ticketEditSchemaData = reactive({
  formEditAttributeLocation,
  formArticleReplyLocation,
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
    isLayout: true,
    component: 'Teleport',
    attrs: {
      style: {
        if: '$newTicketArticlePresent',
        then: 'display: none;',
      },
    },
    props: {
      to: '$formArticleReplyLocation',
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

const { handleScreenBehavior } = useTicketScreenBehavior(currentTaskbarTabId)

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

    currentArticleType.value = undefined

    await nextTick()

    formReset({
      values: {
        article: ticketArticleDefaultValues,
      },
    })
  }
}

// NB: Silence toast notifications for particular errors, these will be handled by the layout taskbar tab component.
const errorCallback = (errorHandler: GraphQLHandlerError) =>
  errorHandler.type !== GraphQLErrorTypes.Forbidden &&
  errorHandler.type !== GraphQLErrorTypes.RecordNotFound

const { isTicketFormGroupValid, initialTicketValue, editTicket } = useTicketEdit(
  ticket,
  form,
  errorCallback,
)

const { openReplyForm } = useTicketArticleReplyAction(form, showTicketArticleReplyForm)

const isFormValid = computed(() => {
  if (!newTicketArticlePresent.value) return isTicketFormGroupValid.value

  return isTicketFormGroupValid.value && isArticleFormGroupValid.value
})

const formAdditionalRouteQueryParams = computed(() => ({
  taskbarId: currentTaskbarTabId.value,
}))

const { notify } = useNotifications()

const checkSubmitEditTicket = () => {
  if (!isFormValid.value) {
    if (activeSidebar.value !== 'information') switchSidebar('information')

    if (newTicketArticlePresent.value && !isArticleFormGroupValid.value && !isReplyPinned.value)
      scrollToArticle('end')
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
      headerTitle: __('Incomplete ticket checklist'),
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
  component: () => import('./TimeAccountingFlyout.vue'),
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

const { activeMacro, executeMacro, disposeActiveMacro } = useTicketMacros(formSubmit)

const submitEditTicket = async (formData: FormSubmitData<TicketUpdateFormData>) => {
  let data = cloneDeep(formData)
  if (currentArticleType.value?.updateForm) data = currentArticleType.value.updateForm(data)

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
        watch(articleResult, () => scrollToArticle('end'), {
          once: true,
        })

        // Reset article form after ticket update and reset form.
        newTicketArticlePresent.value = false

        return {
          reset: (values: FormSubmitData<TicketUpdateFormData>, formNodeValues: FormValues) => {
            nextTick(() => {
              if (!formNodeValues) return

              formReset({
                values: {
                  ticket: formNodeValues.ticket,
                  article: ticketArticleDefaultValues,
                },
              })
            })
          },
        }
      }

      return false
    })
    .catch((error) => {
      if (error instanceof UserError) {
        if (error.getFirstErrorException()) return handleUserErrorException(error)
        skipValidators.value.length = 0
        timeAccountingData.value = undefined
        if (form.value?.formNode) {
          setErrors(form.value.formNode, error)
          return
        }
      }

      skipValidators.value.length = 0
      timeAccountingData.value = undefined
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

  // Reset only the article group.
  currentArticleType.value = undefined

  await nextTick()

  articleFormGroupNode.value?.reset(ticketArticleDefaultValues)

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
    (newValue, oldValue) => {
      if (newTicketArticlePresent.value === newValue) return
      const oldNewTicketArticlePresent = newTicketArticlePresent.value

      newTicketArticlePresent.value = newValue ?? false

      if (oldNewTicketArticlePresent && oldValue !== undefined && oldValue && !newValue) {
        // Reset only the article group.
        currentArticleType.value = undefined

        nextTick(() => {
          articleFormGroupNode.value?.reset()
        })
      }
    },
    { immediate: true },
  )
}

const articleListTopPadding = ref('4rem')
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
        data-test-id="ticket-detail-content-container"
        class="grid w-full overflow-y-auto overscroll-contain"
        :class="{
          'grid-rows-[max-content_max-content_max-content]':
            !newTicketArticlePresent || !isReplyPinned,
          'grid-rows-[max-content_1fr_max-content]': newTicketArticlePresent && isReplyPinned,
        }"
      >
        <TicketDetailTopBar
          ref="detail-top-bar"
          :content-container-element="contentContainerElement"
        />

        <ArticleList
          :style="{
            'padding-top': articleListTopPadding,
          }"
          :is-loading-articles="isLoadingArticles"
          @scroll-to-end="handleInitialScrollToEnd"
        />

        <CommonIndicator v-model="isReachingBottom" class="h-0.5" />

        <ArticleReply
          v-if="ticket?.id && isTicketEditable"
          v-show="!isLoadingArticles && isInitialSettled"
          v-model:pinned="isReplyPinned"
          :ticket="ticket"
          :new-article-present="newTicketArticlePresent"
          :create-article-type="ticket.createArticleType?.name"
          :ticket-article-types="ticketArticleTypes"
          :is-ticket-customer="isTicketCustomer"
          :has-internal-article="hasInternalArticle"
          :parent-reached-bottom-scroll="isReachingBottom"
          :new-article-count="articleCount"
          @show-article-form="handleShowArticleForm"
          @discard-form="discardReplyForm"
          @scroll-into-view="handleScrollToArticle('smooth')"
        />

        <div id="wrapper-form-ticket-edit" class="hidden" aria-hidden="true">
          <Form
            v-if="ticket?.id && initialTicketValue"
            :id="`form-ticket-edit-${internalId}`"
            ref="form"
            :form-id="currentTaskbarTabFormId"
            :schema="ticketEditSchema"
            :disabled="!isTicketEditable"
            :flatten-form-groups="['ticket']"
            :hidden-form-groups="hiddenFormGroups"
            :handlers="[articleTypeHandler(), signatureHandling('body')]"
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
            @submit="submitEditTicket($event as FormSubmitData<TicketUpdateFormData>)"
            @settled="onEditFormSettled"
          />
        </div>
      </div>
    </CommonLoader>
    <!-- Render underlying components only when the ticket is available to avoid providing undefined ticket context -->
    <template v-if="!!ticket" #sideBar="{ isCollapsed, toggleCollapse }">
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
