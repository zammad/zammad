<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { FormRef } from '#shared/components/Form/types.ts'
import type { MacroById } from '#shared/entities/macro/types.ts'
import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import TicketScreenBehavior from '#desktop/pages/ticket/components/TicketDetailView/TicketScreenBehavior/TicketScreenBehavior.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import TicketAgentUpdateButton from './TicketAgentUpdateButton.vue'
import TicketLiveUsers from './TicketLiveUsers.vue'
import TicketSharedDraftZoom from './TicketSharedDraftZoom.vue'

export interface Props {
  dirty: boolean
  disabled: boolean
  isTicketEditable: boolean
  isTicketAgent: boolean
  ticketId: string
  groupId?: string
  form?: FormRef
  hasAvailableDraft?: boolean
  canUseDraft?: boolean
  sharedDraftId?: string | null
  liveUserList: TicketLiveAppUser[]
  setSkipNextStateUpdate: (skip: boolean) => void
}

defineProps<Props>()

defineEmits<{
  submit: [MouseEvent]
  discard: [MouseEvent]
  'execute-macro': [MacroById]
}>()

const { ticket } = useTicketInformation()
</script>

<template>
  <div class="flex gap-4 ltr:mr-auto rtl:ml-auto">
    <TicketLiveUsers
      v-if="liveUserList?.length || ticket?.aiAgentRunning"
      :live-user-list="liveUserList"
    />

    <TicketSharedDraftZoom
      v-if="hasAvailableDraft"
      :form="form"
      :shared-draft-id="sharedDraftId"
      :set-skip-next-state-update="setSkipNextStateUpdate"
    />
  </div>

  <template v-if="isTicketEditable">
    <CommonButton
      v-if="dirty"
      size="large"
      variant="danger"
      :disabled="disabled"
      @click="$emit('discard', $event)"
      >{{ $t('Discard your unsaved changes') }}
    </CommonButton>

    <TicketScreenBehavior />

    <TicketAgentUpdateButton
      v-if="isTicketAgent"
      :ticket-id="ticketId"
      :form="form"
      :disabled="disabled"
      :group-id="groupId"
      :can-use-draft="canUseDraft"
      :shared-draft-id="sharedDraftId"
      @submit="$emit('submit', $event)"
      @execute-macro="$emit('execute-macro', $event)"
    />
    <CommonButton
      v-else
      size="large"
      variant="submit"
      type="button"
      :disabled="disabled"
      @click="$emit('submit', $event)"
      >{{ $t('Update') }}
    </CommonButton>
  </template>
</template>
