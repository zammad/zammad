<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useSlots } from 'vue'

const props = defineProps<{ help?: string }>()

const slots = useSlots()

const hasHelp = computed(() => slots.help || props.help)
</script>

<template>
  <div
    v-bind="$attrs"
    class="form-group overflow-hidden rounded-xl bg-gray-500"
    :class="{ 'mb-4': !hasHelp }"
  >
    <slot />
  </div>
  <div v-if="hasHelp" class="mb-4 pt-1 text-xs text-gray-100 ltr:pl-3 rtl:pr-3">
    <slot name="help">
      {{ help }}
    </slot>
  </div>
</template>

<style lang="scss">
.form-group {
  .formkit-outer:not(:last-child) {
    .formkit-inner {
      @apply border-b border-white/10;
    }
  }
}
</style>
