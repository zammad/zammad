<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { FormStep } from '#shared/components/Form/types.ts'

import CommonStepperStep from './CommonStepperStep.vue'

interface Props {
  modelValue: string
  steps: Record<string, FormStep>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:modelValue': [string]
}>()

const localSteps = computed(() => {
  return Object.entries(props.steps).sort(([, a], [, b]) => a.order - b.order)
})
</script>

<template>
  <div class="flex justify-center text-base">
    <template v-for="([name, step], idx) of localSteps" :key="name">
      <div class="flex" :class="{ 'flex-1': idx !== localSteps.length - 1 }">
        <CommonStepperStep
          v-bind="step"
          :selected="name === modelValue"
          @click="emit('update:modelValue', name)"
        />
        <div
          v-if="idx !== localSteps.length - 1"
          class="mx-2 h-px flex-1 self-center bg-white/20"
        />
      </div>
    </template>
  </div>
</template>
