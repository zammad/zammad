<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  loading?: boolean
  error?: string
  center?: boolean
  right?: boolean
  left?: boolean
}

defineProps<Props>()
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
      'items-center justify-center': center,
      'items-center justify-end': right,
      'items-center justify-start': left,
    }"
  >
    <CommonIcon name="loader" animation="spin" />
  </div>
  <div
    v-else-if="error"
    v-bind="$attrs"
    class="flex items-center justify-center gap-2 text-base text-red"
  >
    <CommonIcon name="close-small" />
    <span>{{ $t(error) }}</span>
  </div>
  <slot v-else />
</template>
