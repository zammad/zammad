<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import KnowledgeBaseCategoryIcon from '#desktop/components/KnowledgeBaseCategoryIcon/KnowledgeBaseCategoryIcon.vue'

import type { AutoCompleteKnowledgeBaseCategoryIconOption } from './types.ts'

interface Props {
  option: AutoCompleteKnowledgeBaseCategoryIconOption
}

const props = defineProps<Props>()

// A value restored from the stored codepoint has no name yet — the codepoint stands
//   in for it until the catalog has been searched.
const label = computed(() => props.option.label || String(props.option.value))
</script>

<template>
  <KnowledgeBaseCategoryIcon
    :name="String(props.option.value)"
    :set="props.option.iconSet"
    size="small"
    class="shrink-0"
  />
  <CommonLabel>{{ label }}</CommonLabel>
</template>
