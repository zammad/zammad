<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type {
  CommonSelectOptionEmits,
  CommonSelectOptionProps,
} from '#desktop/components/CommonSelect/types.ts'
import KnowledgeBaseCategoryIcon from '#desktop/components/KnowledgeBaseCategoryIcon/KnowledgeBaseCategoryIcon.vue'

import type { AutoCompleteKnowledgeBaseCategoryIconOption } from './types.ts'

// The full `CommonSelect` option contract is declared even though a grid cell only
//   needs a few of its props, so that the unused ones do not leak onto the root
//   element as attributes.
const props = defineProps<CommonSelectOptionProps>()

const emit = defineEmits<CommonSelectOptionEmits>()

const option = computed(() => props.option as AutoCompleteKnowledgeBaseCategoryIconOption)

const select = () => emit('select', option.value)
</script>

<template>
  <!-- The cell carries the accessible name of the icon, so that the sprite inside it
    can stay decorative. Its focus indicator is inset, since the cells sit flush
    against the clipped edges of the dropdown. -->
  <div
    v-tooltip="option.label"
    class="flex size-10 shrink-0 cursor-pointer items-center justify-center outline-hidden focus-visible:shadow-[inset_0_0_0_1px_var(--color-blue-800)]"
    :class="
      selected
        ? 'bg-blue-800 text-white'
        : 'text-gray-100 hover:bg-blue-600 hover:text-black dark:text-neutral-400 dark:hover:bg-blue-900 dark:hover:text-white'
    "
    tabindex="0"
    role="option"
    :aria-selected="selected"
    :aria-label="option.label"
    data-test-id="select-item"
    :data-value="option.value"
    @click="select"
    @keypress.enter.prevent="select"
    @keypress.space.prevent="select"
  >
    <KnowledgeBaseCategoryIcon :name="String(option.value)" :set="option.iconSet" size="base" />
  </div>
</template>
