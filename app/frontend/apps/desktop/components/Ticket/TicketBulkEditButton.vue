<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

interface Props {
  checkedTicketIds: Set<ID>
  totalCount?: number
}

defineProps<Props>()

defineEmits<{
  'open-flyout': []
}>()

const { hasPermission } = useSessionStore()

const isAgentUser = computed(() => hasPermission('ticket.agent'))

const { isRunning } = storeToRefs(useTicketBulkUpdateStore())
</script>

<template>
  <template v-if="isAgentUser && totalCount">
    <CommonLabel v-if="isRunning" size="small">
      {{ $t('Bulk action in progress…') }}
    </CommonLabel>
    <CommonButton
      v-else-if="checkedTicketIds.size"
      size="medium"
      prefix-icon="collection-play"
      variant="primary"
      @click="$emit('open-flyout')"
    >
      {{ $t('Bulk actions') }}
    </CommonButton>
  </template>
</template>
