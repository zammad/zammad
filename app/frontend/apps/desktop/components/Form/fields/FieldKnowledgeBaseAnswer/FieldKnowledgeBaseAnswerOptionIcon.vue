<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'

import type { AutoCompleteKnowledgeBaseAnswerOption } from './types.ts'

defineProps<{
  option: AutoCompleteKnowledgeBaseAnswerOption
}>()
</script>

<template>
  <KnowledgeBaseAnswerIcon :visibility="option.visibility" />
</template>
