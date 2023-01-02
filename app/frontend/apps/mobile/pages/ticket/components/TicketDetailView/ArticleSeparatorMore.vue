<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  count: number
}

defineProps<Props>()
</script>

<template>
  <div class="relative text-center">
    <div class="line-more absolute top-1/2 z-0 w-full"></div>
    <button
      class="relative select-none rounded-2xl border border-white/80 bg-black px-4 py-1 text-xs text-white/80"
    >
      {{ $t('load %s more', count) }}
    </button>
  </div>
</template>

<style scoped lang="scss">
.line-more {
  height: 1px;
  background: repeating-linear-gradient(
    to right,
    transparent 0 4px,
    rgba(255, 255, 255, 0.4) 4px 8px
  );
}
</style>
