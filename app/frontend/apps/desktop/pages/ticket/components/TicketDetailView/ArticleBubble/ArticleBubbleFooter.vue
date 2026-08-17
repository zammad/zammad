<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { type AttachmentWithUrls } from '#shared/composables/useAttachments.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import type { FilePreview } from '#shared/utils/files.ts'

import CommonFileList from '#desktop/components/CommonFileList/CommonFileList.vue'

interface Props {
  article: TicketArticle
  articleAttachments: AttachmentWithUrls[]
}

defineProps<Props>()

defineEmits<{
  preview: [type: FilePreview, file: AttachmentWithUrls]
}>()
</script>

<template>
  <footer
    v-if="articleAttachments.length > 0"
    class="flex flex-col gap-1 bg-blue-300 p-3 dark:bg-stone-700"
  >
    <div class="flex flex-row">
      <CommonLabel prefix-icon="paperclip" size="small">
        {{ $t('%s attached file(s)', articleAttachments.length) }}
      </CommonLabel>
    </div>
    <!-- Remove the bg and padding to allow parent styling to take effect, without clashing colors -->
    <CommonFileList
      class="bg-transparent! p-0!"
      :files="articleAttachments"
      no-remove
      @preview="(type, file) => $emit('preview', type, file)"
    />
  </footer>
</template>
