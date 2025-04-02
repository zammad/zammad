<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { ObjectLike } from '#shared/types/utils.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  searchTerm: string
  results: ObjectLike[] // Don't need a specific type here
}

defineEmits<{
  'clear-search-input': []
}>()

const props = defineProps<Props>()

const hasResults = computed(() => props.results.length > 0)

const hasSearchTerm = computed(() => props.searchTerm.trim().length > 0)
</script>

<template>
  <div class="flex flex-col items-center gap-4">
    <CommonIcon size="medium" name="search" />
    <template v-if="!hasResults && hasSearchTerm">
      <CommonLabel tag="p">
        {{ $t('No search results for this query.') }}
      </CommonLabel>
      <CommonButton variant="tertiary" @click="$emit('clear-search-input')">
        {{ $t('Clear search') }}
      </CommonButton>
    </template>
    <CommonLabel v-else tag="p">
      {{ $t('Start typing to get the search results.') }}
    </CommonLabel>
  </div>
</template>
