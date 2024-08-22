<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonFilePreview from '#shared/components/CommonFilePreview/CommonFilePreview.vue'
import { useAttachments } from '#shared/composables/useAttachments.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useFilePreviewViewer } from '#desktop/composables/useFilePreviewViewer.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

import { useTicketAttachments } from './useTicketAttachments.ts'

import type { TicketSidebarContentProps } from '../../types.ts'

defineProps<TicketSidebarContentProps>()

const { loading, ticketAttachments } = useTicketAttachments('cache-first')

const { attachments: attachmentsWithUrls } = useAttachments({
  attachments: ticketAttachments,
})

const { showPreview } = useFilePreviewViewer(
  computed(() => attachmentsWithUrls.value),
)
</script>

<template>
  <TicketSidebarContent :title="__('Attachments')" icon="paperclip">
    <CommonLoader :loading="loading">
      <div
        v-if="ticketAttachments && ticketAttachments.length > 0"
        class="flex flex-col rounded-lg bg-blue-200 p-1 text-gray-100 dark:bg-gray-700 dark:text-neutral-400"
      >
        <CommonFilePreview
          v-for="attachment of attachmentsWithUrls"
          :key="attachment.internalId"
          :download-url="attachment.downloadUrl"
          :preview-url="attachment.preview"
          :file="attachment"
          :no-preview="!$c.ui_ticket_zoom_attachments_preview"
          no-remove
          @preview="($event, type) => showPreview(type, attachment)"
        />
      </div>
      <CommonLabel v-else>
        {{ $t('No attached files') }}
      </CommonLabel>
    </CommonLoader>
  </TicketSidebarContent>
</template>
