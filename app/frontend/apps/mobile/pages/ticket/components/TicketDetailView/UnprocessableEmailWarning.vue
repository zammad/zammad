<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AttachmentWithUrls } from '#shared/composables/useAttachments.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { useTicketArticleUnprocessableEmail } from '#shared/entities/ticket-article/composables/useTicketArticleUnprocessableEmail.ts'
import openExternalLink from '#shared/utils/openExternalLink.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'

interface Props {
  article?: TicketArticle
}

const props = defineProps<Props>()

const { isUnprocessableEmail, rawEmail, processingLog } = useTicketArticleUnprocessableEmail(
  () => props.article,
)

const download = (attachment: AttachmentWithUrls) =>
  openExternalLink(attachment.downloadUrl, '_blank', attachment.name)
</script>

<template>
  <div
    v-if="isUnprocessableEmail"
    :id="`article-${article?.internalId}`"
    class="flex flex-col gap-3 rounded-3xl border border-yellow bg-yellow-highlight p-4 text-sm text-yellow"
    role="alert"
  >
    <p>
      {{
        $t(
          'This ticket was created because the email could not be processed. Download the raw email to see what was received, and the processing log to see why processing failed.',
        )
      }}
    </p>
    <div v-if="rawEmail || processingLog" class="flex flex-wrap gap-2">
      <CommonButton
        v-if="rawEmail"
        class="px-3 py-1"
        variant="submit"
        size="small"
        prefix-icon="install"
        @click="download(rawEmail)"
      >
        {{ $t('Download raw email') }}
      </CommonButton>
      <CommonButton
        v-if="processingLog"
        class="px-3 py-1"
        variant="submit"
        size="small"
        prefix-icon="file"
        @click="download(processingLog)"
      >
        {{ $t('Download processing log') }}
      </CommonButton>
    </div>
  </div>
</template>
