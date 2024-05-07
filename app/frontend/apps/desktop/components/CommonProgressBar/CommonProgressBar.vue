<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
export interface Props {
  value?: string
  max?: string
}

defineProps<Props>()
</script>

<template>
  <progress
    class="progress"
    tabindex="0"
    :aria-label="$t('Indicating progress')"
    :value="value"
    :max="max"
  />
</template>

<style scoped>
.progress {
  @apply h-2 rounded-2xl bg-blue-200 dark:bg-gray-700;

  &::-moz-progress-bar {
    @apply rounded-none bg-blue-800;
  }

  &::-webkit-progress-bar {
    @apply rounded-2xl;
  }

  &::-webkit-progress-value {
    @apply rounded-none bg-blue-800;

    transition: width 1s;
  }

  &:indeterminate {
    --progress-color: theme(colors.blue.800);
  }

  &:indeterminate {
    background-image: repeating-linear-gradient(
      90deg,
      var(--progress-color) -1%,
      var(--progress-color) 10%,
      transparent 10%,
      transparent 90%
    );
    background-size: 200%;
    background-position-x: 15%;
    animation: progress-loading 5s ease-in-out infinite;
  }

  &:indeterminate::-moz-progress-bar {
    @apply bg-blue-200 dark:bg-gray-700;

    background-image: repeating-linear-gradient(
      90deg,
      var(--progress-color) -1%,
      var(--progress-color) 10%,
      transparent 10%,
      transparent 90%
    );
    background-size: 200%;
    background-position-x: 15%;
    animation: progress-loading 5s ease-in-out infinite;
  }

  @keyframes progress-loading {
    50% {
      background-position-x: -115%;
    }
  }
}
</style>
