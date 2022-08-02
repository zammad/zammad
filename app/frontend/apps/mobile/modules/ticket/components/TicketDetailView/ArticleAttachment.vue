<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import useApplicationStore from '@shared/stores/application'
import { canDownloadFile } from '@shared/utils/files'
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

const application = useApplicationStore()

const canPreview = computed<boolean>(() => {
  const { attachment } = props

  if (!attachment.type) return false

  const allowedPriviewContentTypes =
    (application.config[
      'active_storage.web_image_content_types'
    ] as string[]) || []

  return allowedPriviewContentTypes.includes(attachment.type)
})

const baseAttachmentUrl = computed(() => {
  const { ticketInternalId, articleInternalId, attachment } = props
  return `/ticket_attachment/${ticketInternalId}/${articleInternalId}/${attachment.internalId}`
})

const canDownload = computed(() => canDownloadFile(props.attachment.type))

const previewUrl = computed(() => `${baseAttachmentUrl.value}?view=preview`)
const attachmentUrl = computed(() => {
  const dispositionParams = canDownload.value ? '?disposition=attachment' : ''
  return `${baseAttachmentUrl.value}${dispositionParams}`
})

const icon = computed(() => getIconByContentType(props.attachment.type))
</script>

<template>
  <!-- maybe it's better to preview in the current page instead of opening new page? -->
  <CommonLink
    class="mb-2 flex w-full cursor-pointer items-center gap-2 rounded-2xl border-[0.5px] p-3 last:mb-0"
    :class="colors.file"
    :aria-label="$t('Download %s', attachment.name)"
    :link="attachmentUrl"
    :download="canDownload ? true : null"
    :target="!canDownload ? '_blank' : ''"
    rest-api
  >
    <div
      v-if="$c.ui_ticket_zoom_attachments_preview"
      class="flex h-9 w-9 items-center justify-center rounded border-[0.5px] p-1"
      :class="colors.icon"
    >
      <img
        v-if="canPreview"
        :src="`${$c.api_path}${previewUrl}`"
        :alt="$t('Image of %s', attachment.name)"
      />
      <CommonIcon v-else size="base" :name="icon" />
    </div>
    <span class="break-words line-clamp-1">
      {{ attachment.name }}
    </span>
    <span
      v-if="attachment.size"
      class="whitespace-nowrap"
      :class="colors.amount"
    >
      {{ humanizaFileSize(attachment.size) }}
    </span>
  </CommonLink>
</template>
