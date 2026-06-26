<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { AppSpecificTicketArticleType } from '#shared/entities/ticket-article/action/plugins/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

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

const countDisplay = computed(() =>
  props.unreadArticleCount > 9 ? '9+' : props.unreadArticleCount,
)

const showUnreadCount = computed(() => props.unreadArticleCount > 0)

const showElement = computed(
  () => !props.isReachingBottom || !props.isReachingTop || showUnreadCount.value,
)

const { hasPermission } = useSessionStore()
const isAgentUser = computed(() => hasPermission('ticket.agent'))

const { defaultArticleType } = useArticleReply(
  toRef(props, 'ticket'),
  toRef(props, 'ticketArticleTypes'),
)

const { transitions } = useTransitionConfig()
</script>

<template>
  <div
    v-if="showElement"
    role="toolbar"
    aria-orientation="vertical"
    :aria-label="$t('Ticket actions')"
    class="grid w-fit gap-1 rounded-(--toolbar-radius) border border-neutral-100 bg-neutral-75/80 p-(--toolbar-p) backdrop-blur-xs [--toolbar-p:0.25rem] [--toolbar-radius:0.75rem] dark:border-gray-900 dark:bg-gray-500/80"
  >
    <Transition :name="transitions.collapseHeight">
      <div v-if="!isReachingBottom && !newArticlePresent && defaultArticleType" class="flex">
        <CommonButton
          v-tooltip="isAgentUser ? $t('Add internal note') : $t('Add reply')"
          size="medium"
          :variant="isAgentUser ? 'tertiary' : 'primary'"
          :icon="isAgentUser ? 'pencil-square' : 'web'"
          class="rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 text-gray-100 dark:border-gray-900 dark:text-neutral-400"
          @click="
            $emit(
              'show-article-form',
              defaultArticleType.articleType,
              defaultArticleType.performReply,
            )
          "
        />
      </div>
    </Transition>

    <Transition :name="transitions.collapseHeight">
      <div v-if="!isReachingTop">
        <div class="flex min-h-0">
          <CommonButton
            ref="scroll-up-button"
            v-tooltip="$t('Scroll to start')"
            size="medium"
            variant="tertiary"
            icon="arrow-up-short"
            class="rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 text-gray-100 dark:border-gray-900 dark:text-neutral-400"
            @click="emit('scroll-to-start')"
          />
        </div>
      </div>
    </Transition>

    <Transition :name="transitions.collapseHeight">
      <div v-if="!isReachingBottom">
        <div class="relative flex min-h-0">
          <CommonButton
            ref="scroll-down-button"
            v-tooltip="$t(showUnreadCount ? 'Scroll to unread article' : 'Scroll to end')"
            size="medium"
            variant="tertiary"
            icon="arrow-down-short"
            class="rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 text-gray-100 dark:border-gray-900 dark:text-neutral-400"
            @click="showUnreadCount ? $emit('scroll-to-unread-article') : $emit('scroll-to-end')"
          />

          <CommonBadge
            v-if="showUnreadCount"
            size="xs"
            class="pointer-events-none absolute inset-e-0 -top-1.5 aspect-square size-4 p-0! ltr:translate-x-1/2 rtl:-translate-x-1/2"
            variant="highlight"
            rounded
            :aria-label="$t('Unread messages count')"
            role="status"
          >
            {{ countDisplay }}
          </CommonBadge>
        </div>
      </div>
    </Transition>
  </div>
</template>
