<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { TicketExternalReferencesIssueTrackerItemLabel } from '#shared/graphql/types.ts'

interface Props {
  badges: TicketExternalReferencesIssueTrackerItemLabel[]
}

defineProps<Props>()
</script>

<template>
  <div
    :aria-label="$t('List of issue labels')"
    class="flex flex-wrap gap-1"
    role="list"
  >
    <CommonBadge
      v-for="label in badges"
      :key="label.title"
      :style="{ backgroundColor: label.color, color: label.textColor }"
      role="listitem"
      class="!rounded-full border-neutral-100 ltr:border rtl:border dark:border-gray-900"
    >
      {{ label.title }}
    </CommonBadge>
  </div>
</template>
