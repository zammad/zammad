<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { NavigationTab, TabBaseProps } from '#desktop/components/CommonTabs/types.ts'

import {
  tabItemClasses,
  tabItemColorClasses,
  tabItemFontSize,
  tabItemIconSize,
} from '../tabsClasses.ts'

const props = defineProps<TabBaseProps<NavigationTab>>()

const emit = defineEmits<{
  select: []
}>()

const isActive = computed(() => props.activeKeys?.includes(props.tabId) ?? false)

const colorClasses = computed(() => tabItemColorClasses(isActive.value, props.disabled))
</script>

<template>
  <CommonLink
    :link="link"
    :disabled="disabled"
    :aria-current="isActive ? 'page' : undefined"
    class="relative z-10 snap-center"
    :class="[tabItemClasses, colorClasses, tabItemFontSize[size]]"
    @click="emit('select')"
  >
    <CommonIcon v-if="icon" :name="icon" :size="tabItemIconSize[size]" decorative />

    <template v-if="label">
      {{ $t(label) }}
    </template>

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
  </CommonLink>
</template>
