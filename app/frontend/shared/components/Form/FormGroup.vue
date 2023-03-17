<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useSlots } from 'vue'

const props = defineProps<{ help?: string; showDirtyMark?: boolean }>()

const slots = useSlots()

const hasHelp = computed(() => slots.help || props.help)
</script>

<template>
  <div
    v-bind="$attrs"
    class="form-group overflow-hidden rounded-xl bg-gray-500"
    :class="{ 'mb-4': !hasHelp, 'form-group-mark-dirty': showDirtyMark }"
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
  &.form-group-mark-dirty .formkit-outer[data-dirty]::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    width: 0.25rem;
    background: repeating-linear-gradient(
        45deg,
        rgba(255, 255, 255, 0.1),
        rgba(255, 255, 255, 0.1) 5px,
        transparent 5px,
        transparent 9px
      )
      repeat center;
    background-size: 11px 11px;
  }

  .formkit-outer:not(:last-child) {
    > :last-child {
      @apply border-b border-white/10;
    }
  }
}
</style>
