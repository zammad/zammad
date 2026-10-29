<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AttachmentWithUrls } from '#shared/composables/useAttachments.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { useTicketArticleUnprocessableEmail } from '#shared/entities/ticket-article/composables/useTicketArticleUnprocessableEmail.ts'
import openExternalLink from '#shared/utils/openExternalLink.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

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
  <CommonAlert v-if="isUnprocessableEmail" variant="warning">
    <div class="flex flex-col gap-2">
      <p>
        {{
          $t(
            'This ticket was created because the email could not be processed. Download the raw email to see what was received, and the processing log to see why processing failed.',
          )
        }}
      </p>
      <div
        v-if="rawEmail || processingLog"
        class="flex flex-wrap justify-center gap-2 md:justify-start"
      >
        <CommonButton
          v-if="rawEmail"
          variant="tertiary-light"
          size="small"
          prefix-icon="download"
          @click="download(rawEmail)"
        >
          {{ $t('Download raw email') }}
        </CommonButton>
        <CommonButton
          v-if="processingLog"
          variant="tertiary-light"
          size="small"
          prefix-icon="file-text"
          @click="download(processingLog)"
        >
          {{ $t('Download processing log') }}
        </CommonButton>
      </div>
    </div>
  </CommonAlert>
</template>
