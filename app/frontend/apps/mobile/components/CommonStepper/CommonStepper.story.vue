<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import CommonStepper from './CommonStepper.vue'
import type { CommonStepperStep } from './types'

const modelValue = ref('step1')
const steps: Record<string, CommonStepperStep> = {
  step1: {
    label: '1',
    order: 1,
    errorCount: 0,
    valid: true,
    disabled: false,
    completed: true,
  },
  step2: {
    label: '2',
    order: 2,
    errorCount: 0,
    valid: true,
    disabled: false,
    completed: false,
  },
  step3: {
    label: '3',
    order: 3,
    errorCount: 0,
    valid: true,
    completed: false,
    disabled: true,
  },
  step4: {
    label: '4',
    order: 4,
    errorCount: 3,
    valid: false,
    completed: false,
    disabled: true,
  },
}
</script>

<template>
  <Story>
    <CommonStepper v-model="modelValue" :steps="steps"></CommonStepper>
  </Story>
</template>
