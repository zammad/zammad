<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
export interface Props {
  value?: string
  max?: string
}

const props = defineProps<Props>()
</script>

<template>
  <progress class="progress" :value="props.value" :max="props.max"></progress>
</template>

<style scoped>
.progress {
  @apply rounded-box bg-blue-200 dark:bg-gray-700 h-2;

  &::-moz-progress-bar {
    @apply bg-blue-800 rounded-none;
  }

  &::-webkit-progress-bar {
    @apply rounded-box;
  }

  &::-webkit-progress-value {
    @apply bg-blue-800 rounded-none;

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
