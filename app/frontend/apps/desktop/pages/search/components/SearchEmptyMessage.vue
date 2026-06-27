<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { ObjectLike } from '#shared/types/utils.ts'

interface Props {
  hasActiveSearch: boolean
  results: ObjectLike[] // Don't need a specific type here
}

defineEmits<{
  'clear-search-input': []
}>()

const props = defineProps<Props>()

const hasResults = computed(() => props.results.length > 0)
</script>

<template>
  <div class="flex flex-col items-center gap-4">
    <CommonIcon size="medium" name="search" />
    <template v-if="!hasResults && hasActiveSearch">
      <CommonLabel tag="p">
        {{ $t('No search results for this query.') }}
      </CommonLabel>
    </template>
    <CommonLabel v-else tag="p">
      {{ $t('Start typing or apply filters to get the search results.') }}
    </CommonLabel>
  </div>
</template>
