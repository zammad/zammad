<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { useTicketArticleRetryMediaDownload } from '#shared/entities/ticket-article/composables/useTicketArticleRetryMediaDownload.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  article: TicketArticle
}

const props = defineProps<Props>()

const hasError = computed(() => props.article.mediaErrorState?.error)

const { loading, tryAgain } = useTicketArticleRetryMediaDownload(
  toRef(props.article, 'id'),
)

const retryDownload = async () => {
  try {
    await tryAgain()
  } catch {
    // no-op
  }
}
</script>

<template>
  <CommonAlert v-if="hasError" class="-:rounded-none" variant="warning">
    <div>
      <h2>{{ $t('Failed to load content.') }}</h2>
      <CommonButton
        class="!p-0 !text-current underline hover:outline-transparent dark:hover:outline-transparent"
        size="medium"
        transparent-background
        :disabled="loading"
        @click="retryDownload"
      >
        {{ $t('Retry Attachment Download') }}
      </CommonButton>
    </div>
  </CommonAlert>
</template>
