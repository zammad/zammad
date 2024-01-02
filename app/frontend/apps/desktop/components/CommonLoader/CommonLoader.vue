<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import { markup } from '#shared/utils/markup.ts'
import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'

interface Props {
  loading?: boolean
  error?: string | null
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
    class="flex justify-center items-center"
    role="status"
  >
    <CommonIcon
      class="fill-yellow-300"
      name="spinner"
      animation="spin"
      :label="__('Loading…')"
    />
  </div>
  <CommonAlert v-else-if="error" v-bind="$attrs" variant="danger">
    <span v-html="markup($t(error))" />
  </CommonAlert>
  <slot v-else />
</template>
