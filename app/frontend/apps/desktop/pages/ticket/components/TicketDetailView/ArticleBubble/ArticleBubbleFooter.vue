<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonFilePreview from '#shared/components/CommonFilePreview/CommonFilePreview.vue'
import { type TicketArticleAttachmentWithUrls } from '#shared/composables/useArticleAttachments.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'

interface Props {
  article: TicketArticle
  articleAttachments: TicketArticleAttachmentWithUrls[]
}

defineProps<Props>()

defineEmits<{
  preview: [image: TicketArticleAttachmentWithUrls]
}>()
</script>

<template>
  <footer
    v-if="articleAttachments.length > 0"
    class="flex flex-col gap-1 bg-blue-300 p-3 dark:bg-stone-700"
  >
    <div class="flex flex-row">
      <CommonLabel prefix-icon="paperclip" size="small">
        {{
          articleAttachments.length === 1
            ? $t('1 attached file')
            : $t('%s attached files', articleAttachments.length)
        }}
      </CommonLabel>
    </div>
    <CommonFilePreview
      v-for="attachment of articleAttachments"
      :key="attachment.internalId"
      :download-url="attachment.downloadUrl"
      :preview-url="attachment.preview"
      :file="attachment"
      :no-preview="!$c.ui_ticket_zoom_attachments_preview"
      no-remove
      @preview="$emit('preview', attachment)"
    />
  </footer>
</template>
