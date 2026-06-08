<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'

import type { MetaHeader } from './types'

interface Props {
  context: {
    article: TicketArticle
  }
  metaHeader?: MetaHeader
}

const props = withDefaults(defineProps<Props>(), {
  metaHeader: 'from',
})

const metaAddress = computed(() => {
  const { context, metaHeader } = props

  return context.article[metaHeader]
})
</script>

<template>
  <div
    class="flex flex-wrap gap-1 *:not-last:after:text-sm *:not-last:after:leading-snug *:not-last:after:content-[',']"
  >
    <template v-if="metaAddress?.parsed?.length">
      <template v-for="meta in metaAddress.parsed" :key="`${meta.name}-${meta.emailAddress}`">
        <div v-if="meta.name || meta.emailAddress" class="flex items-center">
          <CommonLabel v-if="meta.name" class="me-1 text-nowrap text-black! dark:text-white!">{{
            meta.name
          }}</CommonLabel>
          <CommonLabel v-if="meta.emailAddress">{{ `<${meta.emailAddress}>` }}</CommonLabel>
        </div>
      </template>
    </template>
    <CommonLabel
      v-else-if="metaAddress?.raw"
      class="me-2 text-nowrap text-black! dark:text-white!"
      >{{ metaAddress?.raw }}</CommonLabel
    >
  </div>
</template>
