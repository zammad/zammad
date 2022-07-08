<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineProps<{
  loading: boolean
}>()
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <div v-if="loading" v-bind="$attrs" class="items-enter flex justify-center">
    <CommonIcon name="loader" animation="spin" />
  </div>
  <slot v-else />
</template>
