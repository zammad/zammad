<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  label: string
  selected: boolean
  completed: boolean
  valid: boolean
  disabled: boolean
  errorCount: number
}>()

const classes = computed(() => {
  if (props.selected) return 'bg-white text-black'
  if (props.completed && !props.valid) return 'bg-red-dark'
  if (props.completed) return 'bg-gray-400'
  return 'text-white/70'
})
</script>

<template>
  <button
    class="flex h-6 w-6 grow-0 items-center justify-center rounded-full"
    :disabled="disabled"
    :class="classes"
  >
    <div
      v-if="completed && errorCount"
      role="status"
      :aria-label="$t('Invalid values in step %s', label)"
      aria-live="assertive"
      class="absolute ml-6 mb-3 h-4 min-w-[1rem] rounded-full bg-red px-1 text-center text-xs text-black"
    >
      {{ errorCount }}
    </div>
    <template v-if="selected">{{ label }}</template>
    <CommonIcon
      v-else-if="completed && !valid"
      decorative
      name="mobile-close"
      size="tiny"
      class="text-red-bright"
    />
    <CommonIcon
      v-else-if="completed"
      :aria-label="$t('Step %s is completed', label)"
      name="mobile-check"
      size="tiny"
      class="text-blue"
    />
    <template v-else>{{ label }}</template>
  </button>
</template>
