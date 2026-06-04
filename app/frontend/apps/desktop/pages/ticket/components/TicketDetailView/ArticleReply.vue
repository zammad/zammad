<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
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
}

const props = defineProps<Props>()

defineEmits<{
  'show-article-form': [
    articleType: string,
    performReply: AppSpecificTicketArticleType['performReply'],
  ]
  'discard-form': []
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
      label: type.buttonLabel,
      icon: type.icon,
      performReply: (() =>
        type.performReply?.(props.ticket)) as AppSpecificTicketArticleType['performReply'],
    }
  })
})

const noteArticleType = computed(() =>
  availableArticleTypes.value.find((t) => t.articleType === 'note'),
)

const customerReplyArticleType = computed(() =>
  availableArticleTypes.value.find((t) => t.articleType === 'web'),
)
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
  <div v-else-if="newArticlePresent !== undefined">
    <div class="mx-auto flex w-full max-w-6xl flex-col items-center gap-3 px-12 pt-4 pb-6">
      <CommonButton
        v-if="isTicketCustomer && customerReplyArticleType"
        variant="primary"
        size="small"
        :prefix-icon="customerReplyArticleType.icon"
        @click="
          $emit(
            'show-article-form',
            customerReplyArticleType.articleType,
            customerReplyArticleType.performReply,
          )
        "
      >
        {{ $t(customerReplyArticleType.label) }}
      </CommonButton>

      <template v-else-if="!isTicketCustomer && noteArticleType">
        <div class="flex flex-row items-center gap-3">
          <CommonButton
            variant="tertiary"
            size="small"
            :prefix-icon="noteArticleType.icon"
            @click="
              $emit('show-article-form', noteArticleType.articleType, noteArticleType.performReply)
            "
          >
            {{ $t(noteArticleType.label) }}
          </CommonButton>

          <CommonLabel
            size="small"
            class="text-center text-sm text-stone-200 dark:text-neutral-500"
          >
            {{ $t('or use the reply actions on articles.') }}
          </CommonLabel>
        </div>
      </template>
    </div>
  </div>
</template>
