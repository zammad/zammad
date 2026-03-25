<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, reactive, toRef } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { transformEditorHtml } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { useMacros, useTicketMacros } from '#shared/entities/macro/composables/useMacros.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import type {
  TicketArticleReceivedFormValues,
  TicketBulkEditFormData,
} from '#shared/entities/ticket/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import {
  EnumBulkUpdateStatusStatus,
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
  type TicketBulkSelectorInput,
  type TicketUpdateInput,
} from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import type { MutationSendError } from '#shared/types/error.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { provideFieldEditorOptions } from '#desktop/components/Form/fields/FieldEditor/useFieldEditorOptions.ts'
import SplitButton from '#desktop/components/SplitButton/SplitButton.vue'
import { useTicketUpdateBulkMutation } from '#desktop/entities/ticket/graphql/mutations/updateBulk.api.ts'
import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

import { closeFlyout } from '../../CommonFlyout/useFlyout.ts'

import type { TicketBulkOverviewContext, TicketBulkSearchContext } from './useTicketBulkEdit.ts'

interface Props {
  ticketIds: ID[]
  groupIds: ID[]
  bulkContext: TicketBulkOverviewContext | TicketBulkSearchContext
  bulkCount: number
  bulkHasMoreItems?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  success: []
  failure: [ID[]]
}>()

const { form, formClearMessage, formSetMessage, formSetErrors, formNodeId, formSubmit } = useForm()

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
          if: '$bulkCount > 0',
          then: {
            if: '$bulkHasMoreItems',
            then: '$t("Max %s ticket(s) selected", $ticketIdsCount)',
            else: '$t("All %s ticket(s) selected", $ticketIdsCount)',
          },
          else: '$t("%s ticket(s) selected", $ticketIdsCount)',
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
            object: EnumObjectManagerObjects.TicketArticle,
            props: {
              mode: ['note'],
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

// To make popover be above the flyout backdrop
provideFieldEditorOptions({ zIndex: '40' })

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

  const contentType = getNodeByName(formId, 'body')?.context?.contentType || 'text/html'

  if (contentType === 'text/html') article.body = transformEditorHtml(article.body)

  return {
    type: article.articleType,
    body: article.body,
    internal: article.internal,
    contentType,
  }
}

const { macrosLoaded, macros } = useMacros(toRef(props, 'groupIds'))
const { activeMacro, executeMacro, disposeActiveMacro } = useTicketMacros(formSubmit)

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

const bulkEditTickets = async (formData: FormSubmitData<TicketBulkEditFormData>) => {
  const store = useTicketBulkUpdateStore()
  const { isRunning } = storeToRefs(store)
  const { setTicketBulkUpdateStatus } = store

  if (isRunning.value) {
    formSetErrors(
      new UserError([
        {
          message: __(
            'Another bulk update is currently in progress. Please wait until it is finished before starting a new one.',
          ),
        },
      ]),
    )

    return
  }

  formClearMessage('ticket-bulk-update-succeeded')

  const cleanedFormData = Object.fromEntries(
    Object.entries(formData).filter(([, value]) => value),
  ) as FormSubmitData<TicketBulkEditFormData>

  const { internalObjectAttributeValues } = useObjectAttributeFormData<TicketBulkEditFormData>(
    EnumObjectManagerObjects.Ticket,
    ticketObjectAttributesLookup.value,
    cleanedFormData,
  )

  const formArticle = formData.article as TicketArticleReceivedFormValues | undefined

  const article = processBulkEditArticle(form.value!.formId, formArticle)

  let selector: TicketBulkSelectorInput = {}

  if (props.bulkCount) {
    if ('overviewId' in props.bulkContext) selector = { overviewId: props.bulkContext.overviewId }
    else if ('searchQuery' in props.bulkContext)
      selector = { searchQuery: props.bulkContext.searchQuery }
    else
      throw new Error(
        // eslint-disable-next-line zammad/zammad-detect-translatable-string
        'Invalid ticket bulk context: bulkCount is positive but no valid context provided',
      )
  } else selector = { ticketIds: props.ticketIds }

  try {
    const result = await updateBulkMutation.send({
      selector,
      perform: {
        input: {
          ...internalObjectAttributeValues,
          article,
        } as TicketUpdateInput,
        macroId: activeMacro.value?.id,
      },
    })

    if (result) {
      const total = result.ticketUpdateBulk?.total || 0

      if (result.ticketUpdateBulk?.async) {
        setTicketBulkUpdateStatus({
          status: EnumBulkUpdateStatusStatus.Pending,
          processedCount: 0,
          total,
        })

        emit('success')
        closeFlyout(flyoutName)

        return
      }

      const failedCount = result.ticketUpdateBulk?.failedCount ?? 0
      const invalidTicketIds = result.ticketUpdateBulk?.invalidTicketIds ?? []
      const invalidTicketCount = invalidTicketIds.length

      // In case there are invalid tickets, show alert messages and allow retry.
      if (invalidTicketCount) {
        // Only if some tickets were processed successfully.
        if (total - failedCount > 0) {
          formSetMessage({
            key: 'ticket-bulk-update-succeeded',
            value: i18n.t('Bulk action successful for %s ticket(s).', total - failedCount),
            type: 'success',
          })
        }

        formSetErrors(
          new UserError([
            {
              message: i18n.t(
                'Bulk action failed for %s ticket(s). Check attribute values and try again.',
                invalidTicketCount,
              ),
            },
          ]),
        )

        emit('failure', invalidTicketIds)

        return
      }

      // Otherwise, close the flyout and show toast messages.
      else if (failedCount) {
        // Only if some tickets were processed successfully.
        if (total - failedCount > 0) {
          notify({
            id: 'ticket-bulk-update-succeeded',
            type: NotificationTypes.Success,
            message: __('Bulk action successful for %s ticket(s).'),
            messagePlaceholder: [(total - failedCount).toString()],
            durationMS: 5000,
          })
        }

        notify({
          id: 'ticket-bulk-update-failed',
          type: NotificationTypes.Error,
          message: __('Bulk action failed for %s ticket(s). Check attribute values and try again.'),
          messagePlaceholder: [failedCount.toString()],
          durationMS: 5000,
        })

        emit('failure', invalidTicketIds)
        closeFlyout(flyoutName)

        return
      }

      notify({
        id: 'ticket-bulk-update-succeeded',
        type: NotificationTypes.Success,
        message: __('Bulk action successful for %s ticket(s).'),
        messagePlaceholder: [total.toString()],
      })

      emit('success')
      closeFlyout(flyoutName)
    }
  } catch (error) {
    formSetErrors(error as MutationSendError)
  } finally {
    disposeActiveMacro()
  }
}

const ticketIdsCount = computed(() => props.bulkCount || props.ticketIds.length)

const schemaData = reactive({
  ticketIdsCount,
  bulkCount: props.bulkCount,
  bulkHasMoreItems: props.bulkHasMoreItems,
})

const formUpdaterAdditionalParams = computed(() => ({
  ticketIds: props.ticketIds.map((id) => getIdFromGraphQLId(id)).join(','),
}))
</script>

<template>
  <CommonFlyout
    :name="flyoutName"
    :header-title="__('Tickets bulk edit')"
    header-icon="collection-play"
    size="large"
    no-close-on-action
  >
    <Form
      id="form-tickets-bulk-edit"
      ref="form"
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterTicketBulkEdit"
      :form-updater-additional-params="formUpdaterAdditionalParams"
      should-autofocus
      use-object-attributes
      :schema="formSchema"
      :schema-data="schemaData"
      @submit="bulkEditTickets($event as FormSubmitData<TicketBulkEditFormData>)"
    />
    <template #footer="{ close }">
      <div class="flex items-center justify-end gap-4">
        <CommonButton size="large" variant="secondary" @click="close">
          {{ $t('Cancel & go back') }}
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
        <CommonButton v-else type="submit" size="large" variant="submit" :form="formNodeId">
          {{ $t('Apply') }}
        </CommonButton>
      </div>
    </template>
  </CommonFlyout>
</template>
