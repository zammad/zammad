<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonTabGroup from '#desktop/components/CommonTabs/CommonTabGroup/CommonTabGroup.vue'
import type { Tab } from '#desktop/components/CommonTabs/types.ts'

import type { KnowledgeBaseSortingScope } from '../../types'

export interface Props {
  categoryCount: number
  answerCount: number
  // Puts the answers entry first. The page order - categories above answers - is what the entries
  //   follow by default; a listing that leads with the answers wants them led with here too.
  reverseOrder?: boolean
}

const props = defineProps<Props>()

const activeTab = defineModel<KnowledgeBaseSortingScope>({ required: true })

// Counts are passed through as they are, zero included: an empty entry is what tells an editor
//   that content of that kind belongs here, and where the next one will land.
const tabs = computed<Tab[]>(() => {
  const items: Tab[] = [
    { key: 'categories', label: __('Categories'), count: props.categoryCount },
    { key: 'answers', label: __('Answers'), count: props.answerCount },
  ]

  return props.reverseOrder ? items.toReversed() : items
})
</script>

<!-- `@container`, because the entries are responsive to the room they are given rather than to the
     window: CommonTab keeps its label behind an `@lg` container query, so without a container
     ancestor every entry collapses to a bare count. Same wrapper the other tab groups bring along
     (see SearchControls.vue). -->
<template>
  <div class="@container flex w-full">
    <CommonTabGroup
      v-model="activeTab"
      :tabs="tabs"
      :label="$t('Content type')"
      size="medium"
      class="min-w-0"
    />
  </div>
</template>
