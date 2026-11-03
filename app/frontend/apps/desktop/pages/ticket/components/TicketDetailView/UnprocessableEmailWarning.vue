<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

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

const hasActions = computed(() => Boolean(rawEmail.value || processingLog.value))

const download = (attachment: AttachmentWithUrls) =>
  openExternalLink(attachment.downloadUrl, '_blank', attachment.name)
</script>

<template>
  <div v-if="isUnprocessableEmail" class="flex flex-col" data-test-id="unprocessable-email-warning">
    <!-- The actions overlap the lower edge of the alert, as the article actions do on a bubble. -->
    <CommonAlert variant="warning" :class="{ '-mb-3.5 pb-4.5': hasActions }">
      <p>
        {{
          $t(
            'This ticket was created because the email could not be processed. Download the raw email to see what was received, and the processing log to see why processing failed.',
          )
        }}
      </p>
    </CommonAlert>
    <div v-if="hasActions" class="flex flex-wrap gap-1.5 px-3">
      <CommonButton
        v-if="rawEmail"
        variant="tertiary-light"
        size="medium"
        class="py-0.75! text-normal!"
        prefix-icon="download"
        @click="download(rawEmail)"
      >
        {{ $t('Download raw email') }}
      </CommonButton>
      <CommonButton
        v-if="processingLog"
        variant="tertiary-light"
        size="medium"
        class="py-0.75! text-normal!"
        prefix-icon="file-text"
        @click="download(processingLog)"
      >
        {{ $t('Download processing log') }}
      </CommonButton>
    </div>
  </div>
</template>
