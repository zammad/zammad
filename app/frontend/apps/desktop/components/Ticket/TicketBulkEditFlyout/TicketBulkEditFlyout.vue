<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, reactive, toRef } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { populateEditorNewLines } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import {
  useMacros,
  useTicketMacros,
} from '#shared/entities/macro/composables/useMacros.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { getTicketNumberWithHook } from '#shared/entities/ticket/composables/getTicketNumber.ts'
import type {
  TicketArticleReceivedFormValues,
  TicketBulkEditFormData,
} from '#shared/entities/ticket/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
  type TicketUpdateBulkUserError,
  type TicketUpdateInput,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { MutationSendError } from '#shared/types/error.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import SplitButton from '#desktop/components/SplitButton/SplitButton.vue'
import { useTicketUpdateBulkMutation } from '#desktop/entities/ticket/graphql/mutations/updateBulk.api.ts'

import { closeFlyout } from '../../CommonFlyout/useFlyout.ts'

interface Props {
  ticketIds: ID[]
  groupIds: ID[]
}

const props = defineProps<Props>()

const emit = defineEmits<{
  success: []
}>()

const application = useApplicationStore()

const { form, formSetErrors, formNodeId, formSubmit } = useForm()

const flyoutName = 'tickets-bulk-edit'

const formSchema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        isLayout: true,
        component: 'CommonLabel',
        children: {
          if: '$ticketIdsCount === 1',
          then: '$t("%s ticket selected", $ticketIdsCount)',
          else: '$t("%s tickets selected", $ticketIdsCount)',
        },
      },
      {
        name: 'group_id',
        screen: 'overview_bulk',
        object: EnumObjectManagerObjects.Ticket,
      },
      {
        name: 'owner_id',
        screen: 'overview_bulk',
        object: EnumObjectManagerObjects.Ticket,
      },
      {
        name: 'state_id',
        screen: 'overview_bulk',
        object: EnumObjectManagerObjects.Ticket,
      },
      {
        name: 'pending_time',
        screen: 'overview_bulk',
        object: EnumObjectManagerObjects.Ticket,
      },
      {
        name: 'priority_id',
        screen: 'overview_bulk',
        object: EnumObjectManagerObjects.Ticket,
      },
      {
        name: 'showArticle',
        type: 'toggle',
        label: __('Note'),
        props: {
          variants: {
            true: 'yes',
            false: 'no',
          },
        },
      },
      {
        if: '$values.showArticle === true',
        type: 'group',
        name: 'article',
        isGroupOrList: true,
        children: [
          {
            name: 'articleType',
            type: 'hidden',
            value: 'note',
          },
          {
            name: 'body',
            screen: 'edit',
            object: EnumObjectManagerObjects.TicketArticle,
            props: {
              // Disable all the advanced features for now.
              meta: {
                mentionText: {
                  disabled: true,
                },
                mentionKnowledgeBase: {
                  disabled: true,
                },
                mentionUser: {
                  disabled: true,
                },
                image: {
                  disabled: true,
                },
              },
            },
            required: true,
          },
          {
            name: 'internal',
            label: __('Visibility'),
            type: 'select',
            props: {
              options: [
                {
                  value: false,
                  label: __('Public'),
                  icon: 'unlock',
                },
                {
                  value: true,
                  label: __('Internal'),
                  icon: 'lock',
                },
              ],
            },
          },
        ],
      },
    ],
  },
])

const { attributesLookup: ticketObjectAttributesLookup } = useObjectAttributes(
  EnumObjectManagerObjects.Ticket,
)

const { notify } = useNotifications()

const updateBulkMutation = new MutationHandler(useTicketUpdateBulkMutation(), {
  errorShowNotification: false,
})

const processBulkEditArticle = (
  formId: string,
  article: TicketArticleReceivedFormValues | undefined,
) => {
  if (!article) return null

  const contentType =
    getNodeByName(formId, 'body')?.context?.contentType || 'text/html'

  if (contentType === 'text/html') {
    article.body = populateEditorNewLines(article.body)
  }

  return {
    type: article.articleType,
    body: article.body,
    internal: article.internal,
    contentType,
  }
}

const { macrosLoaded, macros } = useMacros(toRef(props, 'groupIds'))
const { activeMacro, executeMacro, disposeActiveMacro } =
  useTicketMacros(formSubmit)

const macroMenuItems = computed<MenuItem[]>(
  () =>
    macros.value?.map((macro) => ({
      key: macro.id,
      label: macro.name,
      groupLabel: __('Macros'),
      icon: 'play-circle',
      iconClass: 'text-yellow-300',
      onClick: () => executeMacro(macro),
    })) ?? [],
)

const bulkEditTickets = async (
  formData: FormSubmitData<TicketBulkEditFormData>,
) => {
  const cleanedFormData = Object.fromEntries(
    Object.entries(formData).filter(([, value]) => value),
  ) as FormSubmitData<TicketBulkEditFormData>

  const { internalObjectAttributeValues } =
    useObjectAttributeFormData<TicketBulkEditFormData>(
      ticketObjectAttributesLookup.value,
      cleanedFormData,
    )

  const formArticle = formData.article as
    | TicketArticleReceivedFormValues
    | undefined

  const article = processBulkEditArticle(form.value!.formId, formArticle)

  try {
    const result = await updateBulkMutation.send({
      ticketIds: props.ticketIds,
      input: {
        ...internalObjectAttributeValues,
        article,
      } as TicketUpdateInput,
      macroId: activeMacro.value?.id,
    })

    if (result) {
      notify({
        id: 'tickets-updated-bulk',
        type: NotificationTypes.Success,
        message: __('The %s selected tickets have been updated successfully.'),
        messagePlaceholder: [props.ticketIds.length.toString()],
      })

      emit('success')
      closeFlyout(flyoutName)
    }
  } catch (error) {
    if (error instanceof UserError) {
      const firstError = error.errors[0] as TicketUpdateBulkUserError

      if (firstError.failedTicket) {
        formSetErrors(
          new UserError([
            {
              message: i18n.t(
                `Ticket failed to save: %s (Reason: %s)`,
                `${getTicketNumberWithHook(
                  application.config.ticket_hook,
                  firstError.failedTicket.number,
                )} - ${firstError.failedTicket.title}`,
                firstError.message,
              ),
            },
          ]),
        )

        return
      }
    }

    formSetErrors(error as MutationSendError)
  } finally {
    disposeActiveMacro()
  }
}

const ticketIdsCount = computed(() => props.ticketIds.length)

const schemaData = reactive({
  ticketIdsCount,
})
</script>

<template>
  <CommonFlyout
    :name="flyoutName"
    :header-title="__('Tickets Bulk Edit')"
    header-icon="collection-play"
    size="large"
    no-close-on-action
  >
    <Form
      id="form-tickets-bulk-edit"
      ref="form"
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketBulkEdit"
      should-autofocus
      use-object-attributes
      :schema="formSchema"
      :schema-data="schemaData"
      @submit="
        bulkEditTickets($event as FormSubmitData<TicketBulkEditFormData>)
      "
    />
    <template #footer="{ close }">
      <div class="flex items-center justify-end gap-4">
        <CommonButton size="large" variant="secondary" @click="close">
          {{ $t('Cancel & Go Back') }}
        </CommonButton>
        <SplitButton
          v-if="!macrosLoaded || macroMenuItems.length"
          type="submit"
          size="large"
          variant="submit"
          :items="macroMenuItems"
          :form="formNodeId"
        >
          {{ $t('Apply') }}
        </SplitButton>
        <CommonButton
          v-else
          type="submit"
          size="large"
          variant="submit"
          :form="formNodeId"
        >
          {{ $t('Apply') }}
        </CommonButton>
      </div>
    </template>
  </CommonFlyout>
</template>
