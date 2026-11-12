<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonTranslateRenderer from '#shared/components/CommonTranslateRenderer/CommonTranslateRenderer.vue'

import type { ChatTopic } from '#desktop/entities/chat/types.ts'

import ChatAcceptButton from './ChatAcceptButton.vue'
import ChatCountBadge from './ChatCountBadge.vue'

interface Props {
  topic: ChatTopic
  count: number
  // The reason the accept buttons of all topics share while they are disabled.
  limitReasonId?: string
}

defineProps<Props>()
</script>

<template>
  <div class="flex items-center gap-2">
    <ChatCountBadge :count="count" highlight />
    <CommonTranslateRenderer
      as="span"
      class="text-sm/snug text-normal"
      :source="__('Waiting in %s')"
      :placeholders="[
        { type: 'label', props: { size: 'medium', class: 'font-bold' }, content: topic.name },
      ]"
    />
    <ChatAcceptButton class="ms-auto" :topic="topic" :aria-describedby="limitReasonId" />
  </div>
</template>
