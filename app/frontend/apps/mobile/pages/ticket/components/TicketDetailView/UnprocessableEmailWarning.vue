<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { AttachmentWithUrls } from '#shared/composables/useAttachments.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { useTicketArticleUnprocessableEmail } from '#shared/entities/ticket-article/composables/useTicketArticleUnprocessableEmail.ts'
import openExternalLink from '#shared/utils/openExternalLink.ts'

interface Props {
  article?: TicketArticle
}

const props = defineProps<Props>()

const { isUnprocessableEmail, rawEmail, processingLog } = useTicketArticleUnprocessableEmail(
  () => props.article,
)

const hasActions = computed(() => Boolean(rawEmail.value || processingLog.value))

const download = (attachment: AttachmentWithUrls) =>
  openExternalLink(attachment.downloadUrl, '_blank', attachment.name)
</script>

<template>
  <div
    v-if="isUnprocessableEmail"
    :id="`article-${article?.internalId}`"
    class="flex flex-col items-start py-3"
    role="alert"
  >
    <div
      class="relative w-full rounded-3xl border border-yellow bg-yellow-highlight p-4 text-base text-yellow"
      :class="{ '-mb-3': hasActions }"
    >
      <div
        class="absolute -top-3.5 flex size-7 items-center justify-center rounded-full bg-yellow text-black ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
      >
        <CommonIcon name="warning" size="small" decorative />
      </div>
      <p>
        {{
          $t(
            'This ticket was created because the email could not be processed. Download the raw email to see what was received, and the processing log to see why processing failed.',
          )
        }}
      </p>
    </div>
    <!-- The actions overlap the lower edge of the bubble, as the article actions do. -->
    <div v-if="hasActions" class="relative flex flex-wrap gap-1 ps-2">
      <button
        v-if="rawEmail"
        type="button"
        class="flex items-center gap-1 rounded-lg border border-black bg-yellow px-2 py-1 text-base font-semibold text-black-full"
        @click="download(rawEmail)"
      >
        <CommonIcon name="install" size="small" decorative />
        {{ $t('Raw email') }}
      </button>
      <button
        v-if="processingLog"
        type="button"
        class="flex items-center gap-1 rounded-lg border border-black bg-yellow px-2 py-1 text-base font-semibold text-black-full"
        @click="download(processingLog)"
      >
        <CommonIcon name="file" size="small" decorative />
        {{ $t('Processing log') }}
      </button>
    </div>
  </div>
</template>
