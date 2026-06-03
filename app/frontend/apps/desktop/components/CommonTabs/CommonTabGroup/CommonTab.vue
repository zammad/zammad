<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import {
  tabItemClasses,
  tabItemColorClasses,
  tabItemFontSize,
  tabItemIconSize,
} from '#desktop/components/CommonTabs/tabsClasses.ts'
import type { Tab, TabBaseProps } from '#desktop/components/CommonTabs/types.ts'

type Props = {
  multiple?: boolean
  canDisplayIconOnly?: boolean
} & TabBaseProps<Tab>

const props = defineProps<Props>()

const isTabMode = computed(() => !props.multiple)

const emit = defineEmits<{
  select: []
}>()

const isActive = computed(() => props.activeKeys?.includes(props.tabId) ?? false)

// Single tabs sit on the strip's sliding marker pill, so they stay transparent.
// Multiselect options have no marker and paint their own active background.
const colorClasses = computed(() =>
  tabItemColorClasses(isActive.value, props.disabled, isTabMode.value),
)
</script>

<template>
  <button
    :role="multiple ? 'option' : 'tab'"
    type="button"
    :disabled="disabled"
    :aria-selected="isActive"
    class="relative z-10 snap-center"
    :aria-controls="isTabMode ? `tab-panel-${tabId}` : undefined"
    :class="[tabItemClasses, colorClasses, tabItemFontSize[size]]"
    @click="emit('select')"
  >
    <CommonIcon v-if="icon" :name="icon" :size="tabItemIconSize[size]" decorative />

    <span v-if="label" :class="{ 'sr-only @lg:not-sr-only': canDisplayIconOnly }">
      {{ $t(label) }}
    </span>

    <!-- Currently we don't need to hide the badge when canDisplayIconOnly is true -->
    <!-- Will have to be re-evaluated if a use-case comes-->
    <CommonBadge
      v-if="count !== undefined"
      class="pointer-events-none leading-snug font-bold"
      :class="classes?.badge"
      size="xs"
      rounded
      aria-hidden="true"
    >
      {{ count }}
    </CommonBadge>
  </button>
</template>
