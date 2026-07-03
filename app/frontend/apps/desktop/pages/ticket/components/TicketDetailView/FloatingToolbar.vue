<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { AppSpecificTicketArticleType } from '#shared/entities/ticket-article/action/plugins/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFloatingToolbar from '#desktop/components/CommonFloatingToolbar/CommonFloatingToolbar.vue'

import { useArticleReply } from './useArticleReply.ts'

export interface Props {
  ticket: TicketById
  ticketArticleTypes: AppSpecificTicketArticleType[]
  unreadArticleCount: number
  isReachingBottom: boolean
  isReachingTop?: boolean
  newArticlePresent?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'show-article-form': [
    articleType: string,
    performReply: AppSpecificTicketArticleType['performReply'],
  ]
  'scroll-to-start': []
  'scroll-to-end': []
  'scroll-to-unread-article': []
}>()

const { hasPermission } = useSessionStore()
const isAgentUser = computed(() => hasPermission('ticket.agent'))

const { defaultArticleType } = useArticleReply(
  toRef(props, 'ticket'),
  toRef(props, 'ticketArticleTypes'),
)

const hidePrimaryAction = computed(
  () => props.isReachingBottom || props.newArticlePresent || !defaultArticleType.value,
)

const handleShowArticleForm = () => {
  if (!defaultArticleType.value) return

  emit(
    'show-article-form',
    defaultArticleType.value.articleType,
    defaultArticleType.value.performReply,
  )
}
</script>

<template>
  <CommonFloatingToolbar
    :label="$t('Ticket actions')"
    :is-reaching-bottom="isReachingBottom"
    :is-reaching-top="isReachingTop"
    :hide-primary-action="hidePrimaryAction"
    :unread-count="unreadArticleCount"
    :unread-tooltip="$t('Scroll to unread article')"
    @scroll-to-start="emit('scroll-to-start')"
    @scroll-to-end="emit('scroll-to-end')"
    @scroll-to-unread="emit('scroll-to-unread-article')"
  >
    <template v-if="defaultArticleType" #primary-action>
      <CommonButton
        v-tooltip="isAgentUser ? $t('Add internal note') : $t('Add reply')"
        size="medium"
        :variant="isAgentUser ? 'tertiary' : 'primary'"
        :icon="isAgentUser ? 'pencil-square' : 'web'"
        class="rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 text-gray-100 dark:border-gray-900 dark:text-neutral-400"
        @click="handleShowArticleForm"
      />
    </template>
  </CommonFloatingToolbar>
</template>
