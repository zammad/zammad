<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'

import type { ChatFooterNote } from './types.ts'

defineProps<{
  note?: ChatFooterNote
}>()
</script>

<template>
  <!-- The end of the conversation: when, centred and muted, and how below. -->
  <div v-if="note" class="flex flex-col items-center gap-2" role="note">
    <CommonDateTime v-if="note.time" class="text-xs text-muted" :date-time="note.time" />

    <CommonLabel class="text-center" size="small">{{ note.text }}</CommonLabel>
  </div>
</template>
