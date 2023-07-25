<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, reactive, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRouter } from 'vue-router'
import { useEventListener } from '@vueuse/core'
import Form from '#shared/components/Form/Form.vue'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
  type TicketCreateInput,
} from '#shared/graphql/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useMultiStepForm } from '#shared/components/Form/useMultiStepForm.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useTicketCreate } from '#shared/entities/ticket/composables/useTicketCreate.ts'
import { useTicketCreateArticleType } from '#shared/entities/ticket/composables/useTicketCreateArticleType.ts'
import { useTicketFormOganizationHandler } from '#shared/entities/ticket/composables/useTicketFormOrganizationHandler.ts'
import type {
  FormSubmitData,
  FormSchemaNode,
} from '#shared/components/Form/types.ts'
import { i18n } from '#shared/i18n.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { ErrorStatusCodes, GraphQLErrorTypes } from '#shared/types/error.ts'
import type UserError from '#shared/errors/UserError.ts'
import { defineFormSchema } from '#mobile/form/defineFormSchema.ts'
import { populateEditorNewLines } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import CommonStepper from '#mobile/components/CommonStepper/CommonStepper.vue'
import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonBackButton from '#mobile/components/CommonBackButton/CommonBackButton.vue'
import { errorOptions } from '#mobile/router/error.ts'
import { useConfirmationDialog } from '#mobile/components/CommonConfirmation/useConfirmationDialog.ts'
import {
  useTicketDuplicateDetectionHandler,
  type TicketDuplicateDetectionPayload,
} from '#mobile/pages/ticket/composable/useTicketDuplicateDetectionHandler.ts'
import { useTicketSignature } from '#shared/composables/useTicketSignature.ts'
import type { TicketFormData } from '#shared/entities/ticket/types.ts'
import { convertFilesToAttachmentInput } from '#shared/utils/files.ts'
import { useDialog } from '#shared/composables/useDialog.ts'
import { useStickyHeader } from '#shared/composables/useStickyHeader.ts'
import type { ApolloError } from '@apollo/client'
import { useTicketCreateMutation } from '../graphql/mutations/create.api.ts'

const router = useRouter()

// Add meta header with selected ticket create article type

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

const { ticketCreateArticleType, ticketArticleSenderTypeField } =
  useTicketCreateArticleType({ onSubmit })

const { isTicketCustomer } = useTicketCreate()

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
        // TODO: check styling for this hint
        class: 'my-10 text-base text-center text-yellow',
      },
      children: '$getAdditionalCreateNote($values.articleSenderType)',
    },
  ],
  true,
)

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

const ticketCreateMutation = new MutationHandler(useTicketCreateMutation({}), {
  errorShowNotification: false,
})

const redirectAfterCreate = (internalId?: number) => {
  if (internalId) {
    router.replace(`/tickets/${internalId}`)
  } else {
    router.replace({ name: 'Home' })
  }
}

const securityIntegration = computed<boolean>(
  () =>
    ((application.config.smime_integration ||
      application.config.pgp_integration) as boolean) ?? false,
)

const { notify } = useNotifications()

const notifySuccess = () => {
  notify({
    type: NotificationTypes.Success,
    message: __('Ticket has been created successfully.'),
  })
}

const handleTicketCreateError = (error: UserError | ApolloError) => {
  if ('graphQLErrors' in error) {
    const graphQLErrors = error.graphQLErrors?.[0]
    // treat this as successful
    if (graphQLErrors?.extensions?.type === GraphQLErrorTypes.Forbidden) {
      notifySuccess()

      return () => redirectAfterCreate()
    }

    notify({
      message: __('Ticket could not be created.'),
      type: NotificationTypes.Error,
    })
  } else {
    notify({
      message: error.generalErrors[0],
      type: NotificationTypes.Error,
    })
  }
}

const createTicket = async (formData: FormSubmitData<TicketFormData>) => {
  const { attributesLookup: ticketObjectAttributesLookup } =
    useObjectAttributes(EnumObjectManagerObjects.Ticket)

  const { internalObjectAttributeValues, additionalObjectAttributeValues } =
    useObjectAttributeFormData(ticketObjectAttributesLookup.value, formData)

  const input = {
    ...internalObjectAttributeValues,
    article: {
      cc: formData.cc,
      body: populateEditorNewLines(formData.body),
      sender: isTicketCustomer.value
        ? 'Customer'
        : ticketCreateArticleType[formData.articleSenderType].sender,
      type: isTicketCustomer.value
        ? 'web'
        : ticketCreateArticleType[formData.articleSenderType].type,
      contentType: 'text/html',
      security: formData.security,
    },
    objectAttributeValues: additionalObjectAttributeValues,
  } as TicketCreateInput

  if (formData.attachments && input.article) {
    input.article.attachments = convertFilesToAttachmentInput(
      formData.formId,
      formData.attachments,
    )
  }

  return ticketCreateMutation
    .send({ input })
    .then((result) => {
      if (result?.ticketCreate?.ticket) {
        notifySuccess()

        return () => {
          const ticket = result.ticketCreate?.ticket

          redirectAfterCreate(
            ticket?.policy.update ? ticket.internalId : undefined,
          )
        }
      }
      return null
    })
    .catch(handleTicketCreateError)
}

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

const { waitForConfirmation } = useConfirmationDialog()

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
</script>

<script lang="ts">
export default {
  beforeRouteEnter(to, from, next) {
    const { ticketCreateEnabled } = useTicketCreate()

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
  <header
    ref="headerElement"
    :style="stickyStyles.header"
    class="border-b-[0.5px] border-white/10 bg-black px-4"
  >
    <div class="grid h-16 grid-cols-[75px_auto_75px]">
      <div
        class="flex cursor-pointer items-center justify-self-start text-base"
      >
        <CommonBackButton fallback="/" />
      </div>
      <h1
        class="flex flex-1 items-center justify-center text-center text-lg font-bold"
      >
        {{ $t('Create Ticket') }}
      </h1>
      <div class="flex items-center justify-self-end text-base">
        <CommonButton
          variant="submit"
          form="ticket-create"
          type="submit"
          :disabled="submitButtonDisabled"
          transparent-background
        >
          {{ $t('Create') }}
        </CommonButton>
      </div>
    </div>
  </header>
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
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate"
      :autofocus="true"
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
