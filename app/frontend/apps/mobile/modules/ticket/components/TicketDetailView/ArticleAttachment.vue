<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { humanizaFileSize } from '@shared/utils/helpers'
import { getIconByContentType } from '@shared/utils/icons'
import { computed } from 'vue'
import type { TicketArticleAttachment } from '../../types/tickets'

interface Colors {
  file: string
  icon: string
  amount: string
}

interface Props {
  attachment: TicketArticleAttachment
  colors: Colors
  ticketInternalId: number
  articleInternalId: number
}

const props = defineProps<Props>()

const canPreview = computed(() => {
  const { attachment } = props
  return attachment.type.startsWith('image/')
})

const previewUrl = computed(() => {
  const { ticketInternalId, articleInternalId, attachment } = props
  return `/ticket_attachment/${ticketInternalId}/${articleInternalId}/${attachment.id}?view=preview`
})

const icon = computed(() => getIconByContentType(props.attachment.type))
</script>

<template>
  <!-- TODO show imple view, if $c.ui_ticket_zoom_attachments_preview is disabled -->
  <button
    :key="attachment.id"
    role="button"
    class="mb-2 flex w-full cursor-pointer items-center gap-2 rounded-2xl border-[0.5px] p-3 last:mb-0"
    :class="colors.file"
    :aria-label="$t('Download %s', attachment.name)"
  >
    <div class="rounded border-[0.5px] p-1" :class="colors.icon">
      <img v-if="canPreview" :src="`${$c.api_path}${previewUrl}`" />
      <CommonIcon v-else :name="icon" />
    </div>
    <span class="break-words line-clamp-1">
      {{ attachment.name }}
    </span>
    <span class="whitespace-nowrap" :class="colors.amount">
      {{ humanizaFileSize(attachment.size) }}
    </span>
  </button>
</template>
