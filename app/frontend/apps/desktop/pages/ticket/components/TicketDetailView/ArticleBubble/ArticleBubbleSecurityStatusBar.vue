<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useArticleSecurity } from '#shared/composables/useArticleSecurity.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'

interface Props {
  article: TicketArticle
}

const props = defineProps<Props>()

const { signingIcon, encryptionIcon, hasError } = useArticleSecurity(
  toRef(props.article),
)
</script>

<template>
  <div
    v-if="article.securityState && !hasError"
    role="list"
    class="flex gap-3 p-3 dark:bg-gray-500"
  >
    <CommonIcon size="xs" role="listitem" :name="encryptionIcon" />
    <CommonIcon size="xs" role="listitem" :name="signingIcon" />
  </div>
</template>
