<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
// https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/

import { ref } from 'vue'

import { useSharedVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'

import { useTooltipControls } from './useTooltipControls.ts'

import type { TooltipItemDescriptor } from './types.ts'

export interface Props {
  name: string
  heading?: string
  messages?: TooltipItemDescriptor[]
}

defineProps<Props>()

const tooltipTriggerElement = ref<HTMLElement>()

const { tooltip: tooltipConfig } = useSharedVisualConfig()
const { tooltipVisible, showTooltip } = useTooltipControls(
  tooltipTriggerElement,
  tooltipConfig,
)
</script>

<template>
  <div class="relative contents">
    <component
      :is="tooltipConfig.type === 'popup' ? 'button' : 'div'"
      ref="tooltipTriggerElement"
      data-test-id="tooltipTrigger"
      type="button"
      tabindex="0"
      :aria-describedby="`tooltip-${name}`"
      @click="tooltipConfig.type === 'popup' && showTooltip()"
    >
      <slot />
    </component>

    <component
      :is="tooltipConfig.component"
      :id="`tooltip-${name}`"
      v-model:state="tooltipVisible"
      :messages="messages"
      :heading="heading"
    />
  </div>
</template>
