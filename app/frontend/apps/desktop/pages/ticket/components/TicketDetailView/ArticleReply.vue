<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types'
import type { AppSpecificTicketArticleType } from '#shared/entities/ticket-article/action/plugins/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import ArticleReplyPinned from './ArticleReplyPinned.vue'
import ArticleReplyUnpinned from './ArticleReplyUnpinned.vue'

interface Props {
  ticket: TicketById
  parentReachedBottomScroll: boolean
  newArticlePresent?: boolean
  createArticleType?: string | null
  ticketArticleTypes: AppSpecificTicketArticleType[]
  isTicketCustomer?: boolean
  hasInternalArticle?: boolean
  newArticleCount?: number
}

const props = defineProps<Props>()

defineEmits<{
  'show-article-form': [
    articleType: string,
    performReply: AppSpecificTicketArticleType['performReply'],
  ]
  'discard-form': []
  'scroll-into-view': []
}>()

const pinned = defineModel<boolean>('pinned')

const currentTicketArticleType = computed(() => {
  if (props.isTicketCustomer) return 'web'
  if (props.createArticleType && ['phone', 'web'].includes(props.createArticleType)) {
    return 'email'
  }
  return props.createArticleType
})

const allowedArticleTypes = computed(() => {
  return ['note', 'phone', currentTicketArticleType.value]
})

const availableArticleTypes = computed(() => {
  const filtered = props.ticketArticleTypes.filter((type) =>
    allowedArticleTypes.value.includes(type.value),
  )

  return filtered.map((type) => {
    return {
      articleType: type.value,
      label:
        currentTicketArticleType.value === type.value && !props.isTicketCustomer
          ? __('Reply to customer')
          : type.buttonLabel,
      icon: type.icon,
      performReply: (() =>
        type.performReply?.(props.ticket)) as AppSpecificTicketArticleType['performReply'],
    }
  })
})
</script>

<template>
  <div
    v-if="newArticlePresent"
    role="complementary"
    aria-labelledby="article-reply-form-title"
    :aria-expanded="!pinned"
    v-bind="$attrs"
    :class="{ 'sticky bottom-0 z-20 self-end': pinned }"
  >
    <ArticleReplyPinned
      v-if="pinned"
      :has-internal-article="hasInternalArticle"
      @discard-form="$emit('discard-form')"
      @toggle-pin="pinned = !pinned"
    />
    <ArticleReplyUnpinned
      v-else
      :has-internal-article="hasInternalArticle"
      @discard-form="$emit('discard-form')"
      @toggle-pin="pinned = !pinned"
    />
  </div>
  <div
    v-else-if="newArticlePresent !== undefined"
    class="sticky bottom-0 z-20 row-start-3 grid w-full grid-cols-[minmax(min-content,1fr)_1fr_minmax(min-content,1fr)] py-1.5 backdrop-blur-2xs"
    :class="{
      'border-t border-t-neutral-100 bg-neutral-50/80 dark:border-t-gray-900 dark:bg-gray-500/80':
        !parentReachedBottomScroll,
    }"
  >
    <div v-if="newArticleCount && !parentReachedBottomScroll" class="relative w-fit self-center">
      <CommonButton
        v-tooltip="$t('Scroll to bottom')"
        class="mx-2.5"
        size="large"
        variant="subtle"
        icon="arrow-sm"
        @click="$emit('scroll-into-view')"
      />

      <CommonBadge
        size="xs"
        class="pointer-events-none absolute -top-1.5 block! max-w-10 min-w-4 truncate rounded-full! px-1! py-0! font-bold ltr:right-0.5 rtl:left-0.5"
        variant="highlight"
        :aria-label="$t('Unread messages count')"
        role="status"
      >
        {{ newArticleCount }}
      </CommonBadge>
    </div>

    <div class="col-start-2 flex items-center justify-center gap-2.5 self-center">
      <CommonButton
        v-for="button in availableArticleTypes"
        :key="button.articleType"
        :prefix-icon="button.icon"
        size="large"
        @click="$emit('show-article-form', button.articleType, button.performReply)"
      >
        {{ $t(button.label) }}
      </CommonButton>
    </div>
  </div>
</template>
