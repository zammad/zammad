<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { markup } from '#shared/utils/markup.ts'

interface Props {
  loading?: boolean
  error?: string | null
  position?: 'center' | 'right' | 'left'
}

withDefaults(defineProps<Props>(), {
  position: 'center',
})
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <div
    v-if="loading"
    v-bind="$attrs"
    class="flex"
    :class="{
      'items-center justify-center': position === 'center',
      'items-center justify-end': position === 'right',
      'items-center justify-start': position === 'left',
    }"
    role="status"
  >
    <CommonIcon :label="__('Loading content')" name="loading" animation="spin" />
  </div>
  <div
    v-else-if="error"
    v-bind="$attrs"
    class="flex items-center justify-center gap-2 text-base text-red-bright"
  >
    <CommonIcon name="close-small" />
    <!--      eslint-disable vue/no-v-html -->
    <span v-html="markup($t(error))" />
  </div>
  <slot v-else />
</template>
