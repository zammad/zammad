<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

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
[data-them='dark'] .progress {
  background-color: var(--color-gray-700);

  &:indeterminate::-moz-progress-bar {
    background-color: var(--color-gray-700);
  }
}

.progress {
  height: 0.5rem;
  overflow: clip;
  border-radius: 1rem;
  background-color: var(--color-blue-200);

  &::-moz-progress-bar {
    border-radius: 0;
    background-color: var(--color-blue-800);
  }

  &::-webkit-progress-bar {
    border-radius: 1rem;
  }

  &::-webkit-progress-value {
    border-radius: 0;
    background-color: var(--color-blue-800);
    transition: width 1s;
  }

  &:indeterminate {
    --progress-color: var(--color-blue-800);
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
    background-color: var(--color-blue-200);
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
