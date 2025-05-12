<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useTicketMergeMutation } from '#shared/entities/ticket/graphql/mutations/merge.api.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { ActionFooterOptions } from '#desktop/components/CommonFlyout/types.ts'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'
import TicketRelationAndRecentLists from '#desktop/pages/ticket/components/TicketDetailView/TicketRelationAndRecentLists/TicketRelationAndRecentLists.vue'
import { useTargetTicketOptions } from '#desktop/pages/ticket/composables/useTargetTicketOptions.ts'

interface Props {
  ticket: TicketById
  currentTaskbarTabId?: string
}

const { deleteTaskbarTab } = useUserCurrentTaskbarTabsStore()

const props = defineProps<Props>()

const { form, updateFieldValues, onChangedField } = useForm()

const { formListTargetTicketOptions, targetTicketId, handleTicketClick } =
  useTargetTicketOptions(onChangedField, updateFieldValues)

const mergeFormSchema = [
  {
    name: 'targetTicketId',
    type: 'ticket',
    label: __('Target ticket'),
    exceptTicketInternalId: props.ticket.internalId,
    options: formListTargetTicketOptions,
    clearable: true,
    required: true,
  },
]

const mergeMutation = new MutationHandler(useTicketMergeMutation(), {
  errorShowNotification: false,
})

const router = useRouter()

const { notify } = useNotifications()

const fllyoutName = 'ticket-merge'

const submitMerge = async (formData: Record<'targetTicketId', string>) => {
  const { targetTicketId } = formData

  await mergeMutation.send({
    sourceTicketId: props.ticket.id,
    targetTicketId,
  })

  notify({
    type: NotificationTypes.Success,
    message: __('Ticket merged successfully'),
  })

  return () => {
    closeFlyout(fllyoutName)
    if (props.currentTaskbarTabId) deleteTaskbarTab(props.currentTaskbarTabId)
    router.push(`/ticket/${getIdFromGraphQLId(targetTicketId)}`)
  }
}

const footerActionOptions = computed<ActionFooterOptions>(() => ({
  actionButton: {
    variant: 'submit',
    type: 'submit',
  },
  actionLabel: __('Merge'),
}))
</script>

<template>
  <CommonFlyout
    :header-title="__('Merge Tickets')"
    header-icon="merge"
    size="large"
    no-close-on-action
    :form="form"
    :footer-action-options="footerActionOptions"
    :name="fllyoutName"
  >
    <div class="space-y-6">
      <Form
        ref="form"
        :schema="mergeFormSchema"
        should-autofocus
        @submit="
          submitMerge(
            $event as FormSubmitData<Record<'targetTicketId', string>>,
          )
        "
      />

      <TicketRelationAndRecentLists
        :customer-id="ticket.customer.id"
        :internal-ticket-id="ticket.internalId"
        :selected-ticket-id="targetTicketId"
        @click-ticket="handleTicketClick"
      />
    </div>
  </CommonFlyout>
</template>
