<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'

interface Props {
  context: {
    article: TicketArticle
  }
  type?: 'from' | 'to' | 'cc'
}

const props = withDefaults(defineProps<Props>(), {
  type: 'from',
})

const getEmailAddress = (article: TicketArticle) => {
  if (props.type === 'from') return article.from?.parsed?.at(0)?.emailAddress
  if (props.type === 'cc') return article.cc?.parsed?.at(0)?.emailAddress

  return article.to?.parsed?.at(0)?.emailAddress
}

const getName = (article: TicketArticle) => {
  if (props.type === 'from')
    return article.from?.parsed?.at(0)?.name || article.from?.raw

  if (props.type === 'cc')
    return article.cc?.parsed?.at(0)?.name || article.cc?.raw

  return article.to?.parsed?.at(0)?.name || article.to?.raw
}

const name = computed(() => getName(props.context.article))

const email = computed(() => getEmailAddress(props.context.article))
</script>

<template>
  <div class="flex gap-2">
    <CommonLabel v-if="name" class="text-black dark:text-white">{{
      $t(name)
    }}</CommonLabel>
    <CommonLabel v-if="email && email !== '-' && email !== name">{{
      `<${email}>`
    }}</CommonLabel>
  </div>
</template>
