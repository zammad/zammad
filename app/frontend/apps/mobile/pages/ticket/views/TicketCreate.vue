<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, reactive } from 'vue'
import Form from '@shared/components/Form/Form.vue'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
  type TicketCreateInput,
} from '@shared/graphql/types'
import { useMultiStepForm, useForm } from '@shared/components/Form'
import { useApplicationStore } from '@shared/stores/application'
import { useTicketCreateArticleType } from '@shared/entities/ticket/composables/useTicketCreateArticleType'
import { ButtonVariant } from '@shared/components/Form/fields/FieldButton/types'
import { useTicketFormOganizationHandling } from '@shared/entities/ticket/composables/useTicketFormOrganizationHandler'
import { FormData, type FormSchemaNode } from '@shared/components/Form/types'
import { i18n } from '@shared/i18n'
import { MutationHandler } from '@shared/server/apollo/handler'
import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import { useObjectAttributeFormData } from '@shared/entities/object-attributes/composables/useObjectAttributeFormData'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import { defineFormSchema } from '@mobile/form/defineFormSchema'
import CommonStepper from '@mobile/components/CommonStepper/CommonStepper.vue'
import CommonBackButton from '@mobile/components/CommonBackButton/CommonBackButton.vue'
// No usage of "type" because of: https://github.com/typescript-eslint/typescript-eslint/issues/5468
import { TicketFormData } from '../types/tickets'
import { useTicketCreateMutation } from '../graphql/mutations/create.api'

// Add meta header with selected ticket create article type
// TODO: add customer version or own view?
// TODO: Signature handling?
// TODO: Security options?
// TODO: Discard changes handling

const {
  multiStepPlugin,
  setMultiStep,
  allSteps,
  activeStep,
  visitedSteps,
  stepNames,
  lastStepName,
} = useMultiStepForm()

const { form, isValid, isDisabled, formSubmit } = useForm()

const application = useApplicationStore()

const { ticketCreateArticleType, ticketArticleSenderTypeField } =
  useTicketCreateArticleType()

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
              class: 'my-10 text-base text-center', // TODO: check size
            },
            children: i18n.t(sectionTitle),
          },
          ...childrens,
        ],
      },
    ],
  }
}

const formSchema = defineFormSchema([
  getFormSchemaGroupSection(
    'ticketTitle',
    __('Set a title for your ticket'),
    [
      {
        name: 'title',
        required: true,
        object: EnumObjectManagerObjects.Ticket,
        screen: 'create_top',
        outerClass: '$reset flex grow items-center',
        wrapperClass: '$reset',
        labelClass: '$reset sr-only',
        blockClass: '$reset',
        innerClass: '$reset',
        inputClass:
          '$reset block bg-transparent border-b-[0.5px] border-white outline-none text-center text-xl placeholder:text-opacity-30', // placeholder: xyz...
        props: {
          placeholder: __('Title'),
        },
      },
    ],
    true,
  ),
  getFormSchemaGroupSection(
    'ticketArticleType',
    __('Select the type of ticket your are creating'),
    [
      {
        ...ticketArticleSenderTypeField,
        outerClass: 'grow flex items-center',
      },
      {
        if: '$existingAdditionalCreateNotes() && $getAdditionalCreateNote($values.articleSenderType) !== undefined',
        isLayout: true,
        element: 'p',
        attrs: {
          class: 'my-10 text-base text-center', // TODO: check size/styling
        },
        children: '$getAdditionalCreateNote($values.articleSenderType)',
      },
    ],
    true,
  ),
  getFormSchemaGroupSection(
    'ticketMetaInformation',
    __('Additional information'),
    [
      {
        isLayout: true,
        component: 'FormGroup',
        children: [
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
              maxlength: 1000,
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
  ),
  getFormSchemaGroupSection('ticketArticleMessage', __('Add a message'), [
    {
      isLayout: true,
      component: 'FormGroup',
      children: [
        {
          name: 'body',
          screen: 'create_top',
          object: EnumObjectManagerObjects.TicketArticle,
          props: {
            meta: {
              mentionUser: {
                groupNodeId: 'group_id',
              },
            },
          },
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
        },
      ],
    },
  ]),
])

const ticketCreateMutation = new MutationHandler(useTicketCreateMutation({}), {
  errorNotificationMessage: __('Ticket could not be created.'),
})

const createTicket = async (formData: FormData<TicketFormData>) => {
  const { notify } = useNotifications()

  const { attributesLookup: ticketObjectAttributesLookup } =
    useObjectAttributes(EnumObjectManagerObjects.Ticket)

  const { internalObjectAttributeValues, additionalObjectAttributeValues } =
    useObjectAttributeFormData(ticketObjectAttributesLookup.value, formData)

  const result = await ticketCreateMutation.send({
    input: {
      ...internalObjectAttributeValues,
      article: {
        // TODO: "from" and "to" needs to be handled on server side
        cc: formData.cc,
        body: formData.body,
        // attachments: {
        //   files: formData.attachments,
        //   formId: formData.formId,
        // },
        sender: ticketCreateArticleType[formData.articleSenderType].sender,
        type: ticketCreateArticleType[formData.articleSenderType].type,
        contentType: 'text/html',
      },
      objectAttributeValues: additionalObjectAttributeValues,
    } as TicketCreateInput,
  })

  if (result) {
    notify({
      type: NotificationTypes.Success,
      message: __('Ticket has been created successfully.'),
    })
  }
}

const additionalCreateNotes = computed(
  () =>
    (application.config.ui_ticket_create_notes as Record<string, string>) || {},
)

const schemaData = reactive({
  activeStep,
  visitedSteps,
  allSteps,
  existingAdditionalCreateNotes: () => {
    return Object.keys(additionalCreateNotes).length > 0
  },
  getAdditionalCreateNote: (value: string) => {
    return i18n.t(additionalCreateNotes.value[value])
  },
})

const submitButtonDisabled = computed(() => {
  return (
    !isValid.value ||
    isDisabled.value ||
    (activeStep.value !== lastStepName.value &&
      visitedSteps.value.length < stepNames.value.length)
  )
})
</script>

<template>
  <header class="border-b-[0.5px] border-white/10 px-4">
    <div class="grid h-16 grid-cols-3">
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
      <div class="flex cursor-pointer items-center justify-self-end text-base">
        <FormKit
          input-class="flex justify-center items-center w-9 h-9 rounded-full text-black text-center formkit-variant-primary:bg-yellow"
          type="button"
          :disabled="submitButtonDisabled"
          @click="formSubmit"
          ><CommonIcon
            :aria-label="__('Create ticket')"
            name="mobile-arrow-up"
            size="base"
        /></FormKit>
      </div>
    </div>
  </header>
  <div class="flex h-full flex-col px-4">
    <Form
      id="ticket-create"
      ref="form"
      class="text-left"
      :schema="formSchema"
      :handlers="[useTicketFormOganizationHandling()]"
      :multi-step-form-groups="Object.keys(allSteps)"
      :schema-data="schemaData"
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate"
      use-object-attributes
      @submit="createTicket($event as FormData<TicketFormData>)"
    >
      <template #after-fields>
        <FormKit
          type="button"
          :outer-class="`mt-8 mb-6 ${
            lastStepName === activeStep ? 'invisible' : ''
          }`"
          :aria-hidden="lastStepName === activeStep"
          wrapper-class="flex grow justify-center items-center"
          input-class="py-2 px-4 w-full h-14 text-xl font-semibold rounded-xl select-none"
          :variant="ButtonVariant.Primary"
          @click="setMultiStep()"
        >
          {{ $t('Continue') }}
        </FormKit>
      </template>
    </Form>
    <CommonStepper v-model="activeStep" :steps="allSteps" class="mb-8 px-8" />
  </div>
</template>
