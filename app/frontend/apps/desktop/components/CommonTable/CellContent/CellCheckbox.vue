<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TableAdvancedItem } from '#desktop/components/CommonTable/types.ts'

interface Props {
  item: TableAdvancedItem
  itemIds?: Set<ID>
}

const props = defineProps<Props>()

const hasRowId = computed(() => props.itemIds?.has(props.item.id))

const checkboxIcon = computed(() =>
  hasRowId.value ? 'check-square' : 'square',
)

const disabled = computed(() =>
  props.item.policy ? !props.item.policy.update : !!props.item.disabled,
)
</script>

<template>
  <div
    role="checkbox"
    class="text-stone-200 group-hover:text-black! group-active:text-white! focus-visible:text-blue-800! focus-visible:outline-0 dark:text-neutral-500 group-hover:dark:text-white!"
    :class="{
      'before:absolute before:top-0 before:z-20 before:h-full before:w-2 before:bg-blue-800 ltr:before:left-0 rtl:before:right-0':
        hasRowId,
      'text-gray-100! dark:text-neutral-400!': hasRowId,
      'group-hover/checkbox:text-blue-800!': !disabled,
      'opacity-30 group-hover:text-gray-100! group-hover:dark:text-neutral-400!':
        disabled,
    }"
    :aria-label="
      disabled
        ? undefined
        : hasRowId
          ? $t('Deselect this entry')
          : $t('Select this entry')
    "
    :tabindex="disabled ? -1 : 0"
    :aria-disabled="!!disabled"
    :aria-description="
      disabled && props.item.policy
        ? $t('You do not have permission to update')
        : undefined
    "
    :aria-checked="!!hasRowId"
  >
    <CommonIcon class="mx-1 w-full" size="xs" :name="checkboxIcon" />
  </div>
</template>
