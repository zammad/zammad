<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

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
  <div :class="classMap.container">
    <div
      :class="classMap.base"
      class="flex h-full items-center focus:outline-none"
    >
      <CommonLink
        v-if="link"
        :link="link"
        :class="classMap.link"
        :aria-label="$t(linkLabel)"
        class="flex items-center justify-center"
        open-in-new-tab
        @click="onLinkClick"
      >
        <CommonIcon :name="linkIcon" size="small" decorative />
      </CommonLink>
    </div>
  </div>
</template>
