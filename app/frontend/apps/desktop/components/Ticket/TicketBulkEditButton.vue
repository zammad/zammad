<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  checkedTicketIds: Set<ID>
}

defineProps<Props>()

defineEmits<{
  'open-flyout': []
}>()

const { hasPermission } = useSessionStore()

const isAgentUser = computed(() => hasPermission('ticket.agent'))
</script>

<template>
  <CommonButton
    v-if="isAgentUser && checkedTicketIds.size"
    data-test-id="ticket-bulk-edit-button"
    size="medium"
    prefix-icon="collection-play"
    variant="primary"
    @click="$emit('open-flyout')"
    >{{ $t('Bulk Actions') }}</CommonButton
  >
</template>
