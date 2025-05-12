<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { computed, markRaw, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTicketSignature } from '#shared/composables/useTicketSignature.ts'
import { useTicketCreate } from '#shared/entities/ticket/composables/useTicketCreate.ts'
import { useTicketCreateArticleType } from '#shared/entities/ticket/composables/useTicketCreateArticleType.ts'
import { useTicketFormOrganizationHandler } from '#shared/entities/ticket/composables/useTicketFormOrganizationHandler.ts'
import type { TicketFormData } from '#shared/entities/ticket/types.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '#shared/graphql/types.ts'
import { useWalker } from '#shared/router/walker.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonContentPanel from '#desktop/components/CommonContentPanel/CommonContentPanel.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { usePage } from '#desktop/composables/usePage.ts'
import { useTicketCreateTitle } from '#desktop/entities/ticket/composables/useTicketCreateTitle.ts'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import { useTaskbarTabStateUpdates } from '#desktop/entities/user/current/composables/useTaskbarTabStateUpdates.ts'
import type { TaskbarTabContext } from '#desktop/entities/user/current/types.ts'

import {
  useProvideTicketSidebar,
  useTicketSidebar,
} from '../../composables/useTicketSidebar.ts'
import {
  TicketSidebarScreenType,
  type TicketSidebarContext,
} from '../../types/sidebar.ts'
import TicketSidebar from '../TicketSidebar.vue'

import ApplyTemplate from './ApplyTemplate.vue'
import TicketDuplicateDetectionAlert from './TicketDuplicateDetectionAlert.vue'

interface Props {
  tabId?: string
}

defineProps<Props>()

const router = useRouter()
const walker = useWalker()
const route = useRoute()

const {
  form,
  isDisabled,
  isDirty,
  isInitialSettled,
  formNodeId,
  values,
  triggerFormUpdater,
} = useForm()

const currentTitle = computed(() => values.value.title as string)
const currentArticleType = computed(
  () => values.value.articleSenderType as string,
)

const { currentViewTitle } = useTicketCreateTitle(
  currentTitle,
  currentArticleType,
)

usePage({
  metaTitle: currentViewTitle,
})

const application = useApplicationStore()

const redirectAfterCreate = (internalId?: number) => {
  if (internalId) {
    router.replace(`/tickets/${internalId}`)
    return
  }

  // Fallback redirect, in case the user has no access to the ticket they just created.
  router.replace({ name: 'Dashboard' })
}

const goBack = () => {
  walker.back('/')
}

const { ticketArticleSenderTypeField } = useTicketCreateArticleType()

const { createTicket, isTicketCustomer } = useTicketCreate(
  form,
  redirectAfterCreate,
)

const defaultTitle = __('New Ticket')

const formSchema = defineFormSchema([
  {
    isLayout: true,
    component: 'CommonContentPanel',
    children: [
      {
        isLayout: true,
        element: 'h1',
        attrs: {
          class:
            'py-2.5 text-center text-xl font-medium leading-snug text-black dark:text-white',
          ariaCurrent: 'page',
        },
        children: '$values.title || $t($defaultTitle)',
      },
      {
        if: '$isTicketCustomer === false',
        ...ticketArticleSenderTypeField,
        outerClass: 'flex justify-center',
      },
      {
        isLayout: true,
        element: 'div',
        attrs: {
          class: 'grid grid-cols-1 gap-2.5',
          role: 'tabpanel',
          ariaLabelledby: '$getTabLabel($values.articleSenderType)',
          id: '$getTabPanelId($values.articleSenderType)',
        },
        children: [
          {
            if: '$existingAdditionalCreateNotes() && $getAdditionalCreateNote($values.articleSenderType) !== undefined',
            isLayout: true,
            component: 'CommonAlert',
            props: {
              variant: 'warning',
            },
            children: '$t($getAdditionalCreateNote($values.articleSenderType))',
          },
          {
            if: '$values.ticket_duplicate_detection.count > 0',
            isLayout: true,
            component: 'TicketDuplicateDetectionAlert',
            props: {
              tickets: '$values.ticket_duplicate_detection.items',
            },
            children: '',
          },
          {
            screen: 'create_top',
            object: EnumObjectManagerObjects.Ticket,
          },
          // Because of the current field screen settings in the backend
          // seed we need to add this manually.
          {
            if: '$values.articleSenderType === "email-out"',
            name: 'cc',
            label: __('CC'),
            type: 'recipient',
            props: {
              multiple: true,
              clearable: true,
            },
          },
          {
            if: '$securityIntegration === true && $values.articleSenderType === "email-out"',
            name: 'security',
            label: __('Security'),
            type: 'security',
          },
          {
            name: 'body',
            screen: 'create_top',
            object: EnumObjectManagerObjects.TicketArticle,
            required: true,
            props: {
              meta: {
                mentionText: {
                  customerNodeName: 'customer_id',
                  groupNodeName: 'group_id',
                },
                mentionUser: {
                  groupNodeName: 'group_id',
                },
                mentionKnowledgeBase: {
                  attachmentsNodeName: 'attachments',
                },
              },
            },
          },
          {
            type: 'file',
            name: 'attachments',
            label: __('Attachment'),
            labelSrOnly: true,
            props: {
              multiple: true,
            },
          },
          {
            name: 'ticket_duplicate_detection',
            type: 'hidden',
            value: {
              count: 0,
              items: [],
            },
          },
          {
            name: 'link_ticket_id',
            type: 'hidden',
          },
          {
            name: 'shared_draft_id',
            type: 'hidden',
          },
          {
            name: 'externalReferences',
            type: 'hidden',
          },
        ],
      },
    ],
  },
  {
    isLayout: true,
    component: 'CommonContentPanel',
    children: [
      {
        isLayout: true,
        element: 'div',
        attrs: {
          class: 'grid grid-cols-2-uneven gap-2.5',
        },
        children: [
          {
            screen: 'create_middle',
            object: EnumObjectManagerObjects.Ticket,
          },
        ],
      },
      {
        screen: 'create_bottom',
        object: EnumObjectManagerObjects.Ticket,
      },
    ],
  },
])

const securityIntegration = computed<boolean>(
  () =>
    (application.config.smime_integration ||
      application.config.pgp_integration) ??
    false,
)

const additionalCreateNotes = computed(
  () =>
    (application.config.ui_ticket_create_notes as Record<string, string>) || {},
)

const schemaData = reactive({
  defaultTitle,
  isTicketCustomer,
  securityIntegration,
  getTabLabel: (value: string) => `tab-label-${value}`,
  getTabPanelId: (value: string) => `tab-panel-${value}`,
  existingAdditionalCreateNotes: () => {
    return Object.keys(additionalCreateNotes).length > 0
  },
  getAdditionalCreateNote: (value: string) => {
    return additionalCreateNotes.value[value]
  },
})

const changedFields = reactive({
  // Workaround until the object attribute for body is required so core worklow is returning it correctly.
  body: {
    required: true,
  },
})

const { signatureHandling } = useTicketSignature()

const tabContext = computed<TaskbarTabContext>((currentContext) => {
  if (!isInitialSettled.value) return {}

  const newContext = {
    formValues: values.value,
    formIsDirty: isDirty.value,
  }

  if (currentContext && isEqual(newContext, currentContext))
    return currentContext

  return newContext
})

const {
  currentTaskbarTab,
  currentTaskbarTabId,
  currentTaskbarTabFormId,
  currentTaskbarTabDelete,
} = useTaskbarTab(tabContext)

const { setSkipNextStateUpdate } = useTaskbarTabStateUpdates(
  currentTaskbarTabId,
  form,
  triggerFormUpdater,
)

const sidebarContext = computed<TicketSidebarContext>(() => ({
  screenType: TicketSidebarScreenType.TicketCreate,
  form: form.value,
  formValues: values.value,
  currentTaskbarTabId,
  setSkipNextStateUpdate,
}))

useProvideTicketSidebar(sidebarContext)

const { hasSidebar } = useTicketSidebar()

const { waitForVariantConfirmation } = useConfirmation()

const discardChanges = async () => {
  const confirm = await waitForVariantConfirmation('unsaved')
  if (!confirm) return

  goBack()
  currentTaskbarTabDelete()
}

const applyTemplate = (templateId: string) => {
  // Skip subscription for the current tab, to avoid not needed form updater requests.
  setSkipNextStateUpdate(true)

  triggerFormUpdater({
    includeDirtyFields: true,
    additionalParams: {
      templateId,
    },
  })
}

const formAdditionalRouteQueryParams = computed(() => ({
  taskbarId: currentTaskbarTab.value?.taskbarTabId,
  ...(route.query || {}),
}))

const submitCreateTicket = async (event: FormSubmitData<TicketFormData>) => {
  return createTicket(event).then((result) => {
    if (!result || result === null || result === undefined) return
    if (typeof result === 'function') result()

    currentTaskbarTabDelete()
  })
}
</script>

<template>
  <LayoutContent
    name="ticket-create"
    background-variant="primary"
    content-alignment="center"
    :show-sidebar="hasSidebar"
  >
    <div class="w-full max-w-screen-xl px-28 py-3.5">
      <Form
        id="ticket-create"
        ref="form"
        :key="tabId"
        :form-id="currentTaskbarTabFormId"
        :schema="formSchema"
        :schema-component-library="{
          CommonContentPanel: markRaw(CommonContentPanel),
          TicketDuplicateDetectionAlert: markRaw(TicketDuplicateDetectionAlert),
        }"
        :schema-data="schemaData"
        :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate"
        :handlers="[
          useTicketFormOrganizationHandler(),
          signatureHandling('body'),
        ]"
        :change-fields="changedFields"
        :form-updater-additional-params="formAdditionalRouteQueryParams"
        use-object-attributes
        form-class="flex flex-col gap-3"
        @submit="submitCreateTicket($event as FormSubmitData<TicketFormData>)"
        @changed="setSkipNextStateUpdate(true)"
      />
    </div>
    <template #sideBar="{ isCollapsed, toggleCollapse }">
      <TicketSidebar
        :context="sidebarContext"
        :is-collapsed="isCollapsed"
        :toggle-collapse="toggleCollapse"
      />
    </template>
    <template #bottomBar>
      <template v-if="isInitialSettled">
        <CommonButton
          v-if="isDirty"
          size="large"
          variant="danger"
          :disabled="isDisabled"
          @click="discardChanges"
          >{{ __('Discard Changes') }}</CommonButton
        >
        <CommonButton v-else size="large" variant="secondary" @click="goBack">{{
          __('Cancel & Go Back')
        }}</CommonButton>
      </template>

      <ApplyTemplate @select-template="applyTemplate" />

      <CommonButton
        size="large"
        variant="submit"
        type="submit"
        :form="formNodeId"
        :disabled="isDisabled"
        >{{ __('Create') }}</CommonButton
      >
    </template>
  </LayoutContent>
</template>
