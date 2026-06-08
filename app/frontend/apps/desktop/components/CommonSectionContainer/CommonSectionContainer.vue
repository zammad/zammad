<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'

export interface Props {
  label: string
  noHeading?: boolean
  alternativeBackground?: boolean
}

const props = defineProps<Props>()
</script>

<template>
  <div
    role="region"
    :aria-label="$t(label)"
    class="rounded-lg p-3"
    :class="{
      'bg-blue-200 dark:bg-gray-500': !props.alternativeBackground,
      'bg-blue-200 dark:bg-gray-700': props.alternativeBackground,
    }"
  >
    <CommonLabel
      v-if="!noHeading"
      size="medium"
      class="mb-2.5 text-black! dark:text-white!"
      tag="h2"
    >
      {{ label }}
    </CommonLabel>
    <slot />
  </div>
</template>
