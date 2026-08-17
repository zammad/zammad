<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useAttachments } from '#shared/composables/useAttachments.ts'
import type { Attachment } from '#shared/entities/attachment/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonFileList from '#desktop/components/CommonFileList/CommonFileList.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useFilePreviewViewer } from '#desktop/composables/useFilePreviewViewer.ts'
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

import TicketSidebarAttachmentContentSkeleton from './TicketSidebarAttachmentContentSkeleton.vue'

interface Props extends TicketSidebarContentProps {
  ticketAttachments: Attachment[]
  loading: boolean
}

const props = defineProps<Props>()

const persistentStates = defineModel<ObjectLike>({ required: true })

const { attachments: attachmentsWithUrls } = useAttachments({
  attachments: toRef(props, 'ticketAttachments'),
})

const { showPreview } = useFilePreviewViewer(computed(() => attachmentsWithUrls.value))
</script>

<template>
  <TicketSidebarContent
    v-model="persistentStates.scrollPosition"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
  >
    <CommonLoader :loading="loading">
      <template #skeleton>
        <TicketSidebarAttachmentContentSkeleton />
      </template>

      <CommonFileList
        v-if="ticketAttachments && ticketAttachments.length > 0"
        :files="attachmentsWithUrls"
        :label="$t('Attached files')"
        no-remove
        @preview="showPreview"
      />
      <CommonLabel v-else>
        {{ $t('No attached files') }}
      </CommonLabel>
    </CommonLoader>
  </TicketSidebarContent>
</template>
