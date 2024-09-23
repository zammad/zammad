<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import type { FormRef } from '#shared/components/Form/types.ts'
import { useTicketSharedDraftZoomUpdateMutation } from '#shared/entities/ticket-shared-draft-zoom/graphql/mutations/ticketSharedDraftZoomUpdate.api.ts'
import type { TicketSharedDraftZoomInput } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'
import { closeDialog } from '#desktop/components/CommonDialog/useDialog.ts'
import { useTicketSharedDraft } from '#desktop/pages/ticket/composables/useTicketSharedDraft.ts'

const props = defineProps<{
  sharedDraftId: string
  sharedDraftParams: TicketSharedDraftZoomInput
  form?: FormRef
}>()

const { notify } = useNotifications()

const { openSharedDraftFlyout } = useTicketSharedDraft()

const close = () => {
  closeDialog('shared-draft-conflict')
}

const draftUpdateMutation = new MutationHandler(
  useTicketSharedDraftZoomUpdateMutation(),
  {
    errorNotificationMessage: __('Draft could not be updated.'),
  },
)

const updateDraft = () => {
  draftUpdateMutation
    .send({
      sharedDraftId: props.sharedDraftId,
      input: props.sharedDraftParams,
    })
    .then(() => {
      close()

      notify({
        id: 'shared-draft-detail-view-updated',
        type: NotificationTypes.Success,
        message: __('Shared draft has been updated successfully.'),
      })
    })
}

const showDraft = () => {
  close()
  openSharedDraftFlyout('detail-view', props.sharedDraftId)
}
</script>

<template>
  <CommonDialog
    name="shared-draft-conflict"
    header-title="Save Draft"
    content="There is an existing draft. Do you want to overwrite it?"
  >
    <template #footer>
      <div
        class="flex items-center gap-2 ltr:justify-end rtl:flex-row-reverse rtl:justify-start"
      >
        <CommonButton size="large" variant="secondary" @click="close()">
          {{ $t('Cancel & Go Back') }}
        </CommonButton>
        <CommonButton
          size="large"
          prefix-icon="file-text"
          variant="tertiary"
          @click="showDraft()"
        >
          {{ $t('Show Draft') }}
        </CommonButton>
        <CommonButton size="large" variant="danger" @click="updateDraft()">
          {{ $t('Overwrite Draft') }}
        </CommonButton>
      </div>
    </template>
  </CommonDialog>
</template>
