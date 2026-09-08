<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import type { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

import { visibilityMeta } from './visibilityMeta.ts'

interface Props {
  // Optional so incomplete answer data (e.g. auto-mocked GraphQL results in tests) renders no state
  //   icon instead of triggering a prop-type warning. Production data always carries a visibility.
  visibility?: EnumKnowledgeBaseVisibility
  size?: Sizes
  showTooltip?: boolean
}

const props = withDefaults(defineProps<Props>(), { size: 'small' })

// Resolves to `undefined` when no visibility is given, so the template renders no icon rather than
//   crashing on incomplete data.
const meta = computed(() => (props.visibility ? visibilityMeta[props.visibility] : undefined))
</script>

<template>
  <CommonIcon
    v-if="meta"
    v-tooltip="showTooltip ? meta.label : undefined"
    :name="meta.icon"
    :size="size"
    :label="!showTooltip ? meta.label : undefined"
    :class="meta.class"
    class="shrink-0"
  />
</template>
