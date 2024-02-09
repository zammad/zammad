<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type { CommonButtonItem } from './types.ts'

export interface Props {
  items: CommonButtonItem[]
}

const props = defineProps<Props>()

const filteredItems = computed(() => {
  return props.items.filter((item) => !item.hidden)
})

const onButtonClick = (item: CommonButtonItem) => {
  if (item.disabled) return
  item.onActionClick?.()
}
</script>

<template>
  <div class="flex flex-wrap gap-2">
    <CommonButton
      v-for="item of filteredItems"
      :key="item.label"
      :variant="item.variant"
      :type="item.type"
      :size="item.size"
      :disabled="item.disabled"
      :prefix-icon="item.icon"
      :class="[
        {
          'opacity-50': item.disabled,
        },
      ]"
      class="basis-full"
      @click="onButtonClick(item)"
    >
      <slot name="item" v-bind="item">
        {{ $t(item.label, ...(item.labelPlaceholder || [])) }}
      </slot>
    </CommonButton>
  </div>
</template>
