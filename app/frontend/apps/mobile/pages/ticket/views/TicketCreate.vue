<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEventListener } from '@vueuse/core'
import { computed, nextTick, reactive, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRouter } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type {
  FormSubmitData,
  FormSchemaNode,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useMultiStepForm } from '#shared/components/Form/useMultiStepForm.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useStickyHeader } from '#shared/composables/useStickyHeader.ts'
import { useTicketSignature } from '#shared/composables/useTicketSignature.ts'
import { useTicketCreate } from '#shared/entities/ticket/composables/useTicketCreate.ts'
import { useTicketCreateArticleType } from '#shared/entities/ticket/composables/useTicketCreateArticleType.ts'
import { useTicketCreateView } from '#shared/entities/ticket/composables/useTicketCreateView.ts'
import { useTicketFormOganizationHandler } from '#shared/entities/ticket/composables/useTicketFormOrganizationHandler.ts'
import type { TicketFormData } from '#shared/entities/ticket/types.ts'
import { useUserQuery } from '#shared/entities/user/graphql/queries/user.api.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { errorOptions } from '#shared/router/error.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonStepper from '#mobile/components/CommonStepper/CommonStepper.vue'
import LayoutHeader from '#mobile/components/layout/LayoutHeader.vue'
import { useDialog } from '#mobile/composables/useDialog.ts'

import {
  useTicketDuplicateDetectionHandler,
  type TicketDuplicateDetectionPayload,
} from '../composable/useTicketDuplicateDetectionHandler.ts'

const router = useRouter()

// TODO: Add meta header with selected ticket create article type.

const { canSubmit, form, node, isDirty, formSubmit } = useForm()

const {
  multiStepPlugin,
  setMultiStep,
  allSteps,
  activeStep,
  visitedSteps,
  stepNames,
  lastStepName,
} = useMultiStepForm(node)

const application = useApplicationStore()

const onSubmit = () => {
  setMultiStep()
}

const { ticketArticleSenderTypeField } = useTicketCreateArticleType({
  onSubmit,
  buttons: true,
})

const redirectAfterCreate = (internalId?: number) => {
  if (internalId) {
    router.replace(`/tickets/${internalId}`)
  } else {
    router.replace({ name: 'Home' })
  }
}

const { createTicket, isTicketCustomer } = useTicketCreate(
  form,
  redirectAfterCreate,
)

const getFormSchemaGroupSection = (
  stepName: string,
  sectionTitle: string,
  childrens: FormSchemaNode[],
  itemsCenter = false,
) => {
  return {
    isLayout: true,
    element: 'section',
    attrs: {
      style: {
        if: `$activeStep !== "${stepName}"`,
        then: 'display: none;',
      },
      class: {
        'flex flex-col h-full min-h-[calc(100vh_-_15rem)]': true,
        'items-center': itemsCenter,
      },
    },
    children: [
      {
        type: 'group',
        name: stepName,
        isGroupOrList: true,
        plugins: [multiStepPlugin],
        children: [
          {
            isLayout: true,
            element: 'h4',
            attrs: {
              class: 'my-10 text-base text-center',
            },
            children: i18n.t(sectionTitle),
          },
          ...childrens,
        ],
      },
    ],
  }
}

const ticketTitleSection = getFormSchemaGroupSection(
  'ticketTitle',
  __('Set a title for your ticket'),
  [
    {
      name: 'title',
      required: true,
      object: EnumObjectManagerObjects.Ticket,
      screen: 'create_top',
      outerClass:
        '$reset formkit-outer w-full grow justify-center flex items-center flex-col',
      wrapperClass: '$reset formkit-disabled:opacity-30 flex w-full',
      labelClass: '$reset sr-only',
      blockClass: '$reset flex w-full',
      innerClass: '$reset flex justify-center items-center px-8 w-full',
      messagesClass: 'pt-2',
      inputClass:
        '$reset formkit-input block bg-transparent grow border-b-[0.5px] border-white outline-none text-center text-xl placeholder:text-white placeholder:text-opacity-50',
      props: {
        placeholder: __('Title'),
        onSubmit,
      },
    },
  ],
  true,
)

const ticketArticleTypeSection = getFormSchemaGroupSection(
  'ticketArticleType',
  __('Select the type of ticket your are creating'),
  [
    {
      ...ticketArticleSenderTypeField,
      outerClass: 'w-full flex grow items-center',
      fieldsetClass: 'grow px-4',
    },
    {
      if: '$existingAdditionalCreateNotes() && $getAdditionalCreateNote($values.articleSenderType) !== undefined',
      isLayout: true,
      element: 'p',
      attrs: {
        class: 'my-10 text-base text-center text-yellow',
      },
      children: '$getAdditionalCreateNote($values.articleSenderType)',
    },
  ],
  true,
)

const locationParams = new URL(window.location.href).searchParams
const customUserId = locationParams.get('customer_id') || undefined

const userOptions = ref<unknown[]>([])

const userQuery = useUserQuery(
  () => ({
    userInternalId: Number(customUserId),
    secondaryOrganizationsCount: 3,
  }),
  {
    // we probably opened this because user was already loaded user on another page,
    // so we should try to get it from cache first, but if someone passed down id
    // we need to still provide correct value
    fetchPolicy: 'cache-first',
    enabled: !!customUserId,
  },
)
userQuery.onResult((r) => {
  if (r.loading) return
  const user = r.data?.user
  if (!user) {
    userOptions.value = []
    return
  }
  userOptions.value = [
    {
      value: user.internalId,
      label: user.fullname || user.phone,
      heading: user.organization?.name,
      user,
    },
  ]
})

const ticketMetaInformationSection = getFormSchemaGroupSection(
  'ticketMetaInformation',
  __('Additional information'),
  [
    {
      isLayout: true,
      component: 'FormGroup',
      children: [
        {
          name: 'ticket_duplicate_detection',
          type: 'hidden',
          value: {
            count: 0,
            items: [],
          },
        },
        {
          screen: 'create_top',
          object: EnumObjectManagerObjects.Ticket,
          name: 'customer_id',
          value: customUserId ? Number(customUserId) : undefined,
          props: {
            options: userOptions,
          },
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
          },
        },
      ],
    },
    {
      isLayout: true,
      component: 'FormGroup',
      children: [
        {
          screen: 'create_middle',
          object: EnumObjectManagerObjects.Ticket,
        },
      ],
    },
    {
      isLayout: true,
      component: 'FormGroup',
      children: [
        {
          screen: 'create_bottom',
          object: EnumObjectManagerObjects.Ticket,
        },
      ],
    },
  ],
)

const ticketArticleMessageSection = getFormSchemaGroupSection(
  'ticketArticleMessage',
  __('Add a message'),
  [
    {
      isLayout: true,
      component: 'FormGroup',
      children: [
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
          props: {
            meta: {
              mentionText: {
                customerNodeName: 'customer_id',
              },
              mentionUser: {
                groupNodeName: 'group_id',
              },
              mentionKnowledgeBase: {
                attachmentsNodeName: 'attachments',
              },
            },
          },
          triggerFormUpdater: false,
        },
      ],
    },
    {
      isLayout: true,
      component: 'FormGroup',
      children: [
        {
          type: 'file',
          name: 'attachments',
          label: __('Attachment'),
          labelSrOnly: true,
          props: {
            multiple: true,
          },
        },
      ],
    },
  ],
)

const customerSchema = [
  ticketTitleSection,
  ticketMetaInformationSection,
  ticketArticleMessageSection,
]

const agentSchema = [
  ticketTitleSection,
  ticketArticleTypeSection,
  ticketMetaInformationSection,
  ticketArticleMessageSection,
]

const formSchema = defineFormSchema(
  isTicketCustomer.value ? customerSchema : agentSchema,
)

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
  activeStep,
  visitedSteps,
  allSteps,
  securityIntegration,
  existingAdditionalCreateNotes: () => {
    return Object.keys(additionalCreateNotes).length > 0
  },
  getAdditionalCreateNote: (value: string) => {
    return i18n.t(additionalCreateNotes.value[value])
  },
})

const submitButtonDisabled = computed(() => {
  return (
    !canSubmit.value ||
    (activeStep.value !== lastStepName.value &&
      visitedSteps.value.length < stepNames.value.length)
  )
})

const moveStep = () => {
  if (activeStep.value === lastStepName.value) {
    formSubmit()
    return
  }
  setMultiStep()
}

const { stickyStyles, headerElement } = useStickyHeader()

const bodyElement = ref<HTMLElement>()

const isScrolledToBottom = ref(true)

const setIsScrolledToBottom = () => {
  isScrolledToBottom.value =
    window.innerHeight +
      document.documentElement.scrollTop -
      (headerElement.value?.clientHeight || 0) >=
    (bodyElement.value?.scrollHeight || 0)
}

watch(
  () => activeStep.value,
  () => {
    nextTick(() => {
      setIsScrolledToBottom()
    })
  },
)

useEventListener('scroll', setIsScrolledToBottom)
useEventListener('resize', setIsScrolledToBottom)

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

const { signatureHandling } = useTicketSignature()

const ticketDuplicateDetectionDialog = useDialog({
  name: 'duplicate-ticket-detection',
  component: () =>
    import('#mobile/components/Ticket/TicketDuplicateDetectionDialog.vue'),
})

const showTicketDuplicateDetectionDialog = (
  data: TicketDuplicateDetectionPayload,
) => {
  ticketDuplicateDetectionDialog.open({
    name: 'duplicate-ticket-detection',
    tickets: data.items,
  })
}

const changedFields = reactive({
  // Workaround until the object attribute for body is required so core worklow is returning it correctly.
  body: {
    required: true,
  },
})
</script>

<script lang="ts">
export default {
  beforeRouteEnter(to, from, next) {
    const { ticketCreateEnabled } = useTicketCreateView()

    if (!ticketCreateEnabled.value) {
      errorOptions.value = {
        title: __('Forbidden'),
        message: __('Creating new tickets via web is disabled.'),
        statusCode: ErrorStatusCodes.Forbidden,
        route: to.fullPath,
      }

      next({
        name: 'Error',
        query: {
          redirect: '1',
        },
        replace: true,
      })

      return
    }

    next()
  },
}
</script>

<template>
  <LayoutHeader
    ref="headerElement"
    class="!h-16"
    :style="stickyStyles.header"
    back-url="/"
    :title="__('Create Ticket')"
  >
    <template #after>
      <CommonButton
        variant="submit"
        form="ticket-create"
        type="submit"
        :disabled="submitButtonDisabled"
        transparent-background
      >
        {{ $t('Create') }}
      </CommonButton>
    </template>
  </LayoutHeader>
  <div
    ref="bodyElement"
    :style="stickyStyles.body"
    class="flex h-full flex-col px-4"
  >
    <Form
      id="ticket-create"
      ref="form"
      class="pb-32 text-left"
      :schema="formSchema"
      :handlers="[
        useTicketFormOganizationHandler(),
        signatureHandling('body'),
        useTicketDuplicateDetectionHandler(showTicketDuplicateDetectionDialog),
      ]"
      :flatten-form-groups="Object.keys(allSteps)"
      :schema-data="schemaData"
      :change-fields="changedFields"
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate"
      should-autofocus
      use-object-attributes
      @submit="createTicket($event as FormSubmitData<TicketFormData>)"
    />
  </div>
  <footer
    :class="{
      'bg-gray-light backdrop-blur-lg': !isScrolledToBottom,
    }"
    class="pb-safe fixed bottom-0 z-10 w-full px-4 transition"
  >
    <FormKit
      :variant="lastStepName === activeStep ? 'submit' : 'primary'"
      type="button"
      outer-class="mt-4 mb-2"
      :disabled="lastStepName === activeStep && submitButtonDisabled"
      wrapper-class="flex grow justify-center items-center"
      input-class="py-2 px-4 w-full h-14 text-lg rounded-xl select-none"
      @click="moveStep()"
    >
      {{ lastStepName === activeStep ? $t('Create ticket') : $t('Continue') }}
    </FormKit>
    <CommonStepper
      v-model="activeStep"
      :steps="allSteps"
      class="mb-8 mt-4 px-8"
    />
  </footer>
</template>
