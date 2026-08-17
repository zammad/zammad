<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useAttachments } from '#shared/composables/useAttachments.ts'
import type { Attachment } from '#shared/entities/attachment/types.ts'

import CommonFileList from '#desktop/components/CommonFileList/CommonFileList.vue'
import { useFilePreviewViewer } from '#desktop/composables/useFilePreviewViewer.ts'

const props = defineProps<{
  attachments?: Maybe<Attachment[]>
}>()

const { attachments } = useAttachments({
  attachments: computed(() => props.attachments ?? []),
})

// Its own viewer, separate from the one the answer body runs for its inline images: the
//   two are distinct sets, so they read as two galleries instead of one mixed one.
const { showPreview } = useFilePreviewViewer(attachments)
</script>

<template>
  <section v-if="attachments.length">
    <CommonFileList
      :files="attachments"
      :label="$t('Attachments')"
      no-remove
      @preview="showPreview"
    />
  </section>
</template>
