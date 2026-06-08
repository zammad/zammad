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
    onLinkClick?: (e: MouseEvent) => void
  }>(),
  {
    linkIcon: 'form-field-link',
    linkLabel: __('Link'),
  },
)

const classMap = getFieldLinkClasses()
</script>

<template>
  <div v-if="link" :class="classMap.container">
    <div :class="classMap.base" class="flex h-full items-center focus:outline-hidden">
      <CommonLink
        v-tooltip="$t(linkLabel)"
        :link="link"
        :class="classMap.link"
        class="flex items-center justify-center"
        open-in-new-tab
        @click="onLinkClick"
      >
        <CommonIcon :name="linkIcon" size="small" decorative />
      </CommonLink>
    </div>
  </div>
</template>
