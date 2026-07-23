<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

interface Props {
  // Optional so incomplete answer data (e.g. auto-mocked GraphQL results in tests) renders no state
  //   icon instead of triggering a prop-type warning. Production data always carries a visibility.
  visibility?: EnumKnowledgeBaseVisibility
  size?: Sizes
  showTooltip?: boolean
}

const props = withDefaults(defineProps<Props>(), { size: 'small' })

// One icon per publication state, each with its own color. Keeping icon and color together here
//   means both the knowledge base answer list and the AI suggestions in the ticket sidebar stay in
//   sync, and `satisfies` makes the compiler flag a state that is missing an icon.
const visibilityMeta = {
  [EnumKnowledgeBaseVisibility.Draft]: {
    icon: 'kb-draft',
    label: __('Draft'),
    class: 'text-neutral-500! dark:text-stone-200!',
  },
  [EnumKnowledgeBaseVisibility.Internal]: {
    icon: 'kb-internal',
    label: __('Internal'),
    class: 'text-blue-800!',
  },
  [EnumKnowledgeBaseVisibility.Published]: {
    icon: 'kb-published',
    label: __('Published'),
    class: 'text-green-400!',
  },
  [EnumKnowledgeBaseVisibility.Archived]: {
    icon: 'kb-archived',
    label: __('Archived'),
    class: 'text-stone-400!',
  },
} as const satisfies Record<
  EnumKnowledgeBaseVisibility,
  { icon: string; label: string; class: string }
>

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
