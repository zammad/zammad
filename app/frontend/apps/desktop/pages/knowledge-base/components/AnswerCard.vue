<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'

import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'

import type { KnowledgeBaseAnswerCompact } from '../types.ts'

// Opening and reading an answer is handled by a separate story; for now the
//   browse view only lists the answers with their visibility color-coding.
defineProps<KnowledgeBaseAnswerCompact>()
</script>

<template>
  <li class="flex items-center gap-3 rounded-xl bg-blue-200 px-3 py-2.5 dark:bg-gray-500">
    <KnowledgeBaseAnswerIcon :visibility="visibility" size="small" />
    <CommonLabel size="medium" class="line-clamp-1! grow">
      {{ title }}
    </CommonLabel>
    <CommonBadge
      v-if="translationMissing"
      v-tooltip="$t('No translation for this locale available')"
      variant="warning"
      size="xs"
      rounded
      class="flex items-center justify-center p-1!"
    >
      <CommonIcon name="translate" size="xs" decorative />
    </CommonBadge>
  </li>
</template>
