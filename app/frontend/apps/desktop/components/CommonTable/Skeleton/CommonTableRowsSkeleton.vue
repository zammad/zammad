<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

interface Props {
  rows?: number
}

withDefaults(defineProps<Props>(), {
  rows: 10,
})
</script>

<template>
  <CommonSkeleton
    v-for="(n, i) in rows"
    :key="n"
    :style="{ 'animation-delay': `${n * 0.1}s` }"
    class="h-10"
    :class="{ invisible: i % 2 }"
  />
</template>
