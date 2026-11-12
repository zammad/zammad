<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ChatFooterNote } from './types.ts'

defineProps<{
  note?: ChatFooterNote
}>()
</script>

<template>
  <CommonLabel v-if="note" size="small" role="status">{{ note.text }}</CommonLabel>
</template>
