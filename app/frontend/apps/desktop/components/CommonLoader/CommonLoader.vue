<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { markup } from '#shared/utils/markup.ts'

interface Props {
  loading?: boolean
  error?: string | null
  size?: Sizes
  noTransition?: boolean
}

withDefaults(defineProps<Props>(), {
  size: 'medium',
})
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <Transition :name="noTransition ? 'none' : 'fade'" mode="out-in">
    <div
      v-if="loading"
      v-bind="$attrs"
      class="flex items-center justify-center"
      role="status"
    >
      <CommonIcon
        class="fill-yellow-300"
        name="spinner"
        :size="size"
        animation="spin"
        :label="__('Loading…')"
      />
    </div>
    <CommonAlert v-else-if="error" v-bind="$attrs" variant="danger">
      <span v-html="markup($t(error))" />
    </CommonAlert>
    <slot v-else />
  </Transition>
</template>
