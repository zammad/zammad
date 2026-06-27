<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getFieldLinkClasses } from './initializeFieldLinkClasses.ts'

import type { RouteLocationRaw } from 'vue-router'

withDefaults(
  defineProps<{
    id: string
    link: RouteLocationRaw
    linkIcon?: string
    linkLabel?: string
    // Render the label as visible text next to the icon instead of only as a tooltip.
    showLinkLabel?: boolean
    onLinkClick?: (e: MouseEvent) => void
    linkSize?: 'small' | 'medium' | 'large'
  }>(),
  {
    linkIcon: 'form-field-link',
    linkLabel: __('Link'),
    showLinkLabel: false,
    linkSize: 'large',
  },
)

const classMap = getFieldLinkClasses()

const iconClassMap = {
  small: 'xs',
  medium: 'tiny',
  large: 'small',
} as const
</script>

<template>
  <div v-if="link" :class="classMap.container">
    <div :class="classMap.base" class="flex h-full items-center focus:outline-hidden">
      <CommonLink
        v-tooltip="showLinkLabel ? undefined : $t(linkLabel)"
        :link="link"
        :class="[classMap.link, { 'text-nowrap': showLinkLabel }]"
        class="flex items-center justify-center"
        :size="linkSize"
        open-in-new-tab
        @click="onLinkClick"
      >
        <CommonIcon v-if="linkIcon" :name="linkIcon" :size="iconClassMap[linkSize]" decorative />
        <span v-if="showLinkLabel">{{ $t(linkLabel) }}</span>
      </CommonLink>
    </div>
  </div>
</template>
