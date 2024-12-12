<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonDropdown from '#desktop/components/CommonDropdown/CommonDropdown.vue'
import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'

import { useApplyTemplate } from '../../composables/useApplyTemplate.ts'

const emit = defineEmits<{
  'select-template': [string]
}>()

const { hasPermission } = useSessionStore()

const { templateList } = useApplyTemplate()

const templateAccess = computed(
  () =>
    templateList &&
    templateList.value.length > 0 &&
    hasPermission('ticket.agent'),
)

const items = computed<DropdownItem[]>(() =>
  templateList.value.map((template) => ({
    key: template.id,
    label: template.name,
  })),
)
</script>

<template>
  <template v-if="templateAccess">
    <CommonDropdown
      :items="items"
      :action-label="$t('Apply Template')"
      orientation="top"
      @handle-action="emit('select-template', $event.key)"
    />
  </template>
</template>
