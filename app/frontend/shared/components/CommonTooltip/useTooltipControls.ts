// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { onKeyStroke, useEventListener } from '@vueuse/core'
import { ref, type Ref } from 'vue'

import stopEvent from '#shared/utils/events.ts'

import type { TooltipVisualConfig } from './types.ts'

export const useTooltipControls = (
  tooltipTrigger: Ref<HTMLElement | undefined>,
  tooltipConfig: TooltipVisualConfig,
) => {
  const tooltipVisible = ref(false)

  const hideTooltip = () => {
    tooltipVisible.value = false
  }

  const showTooltip = () => {
    tooltipVisible.value = true
  }

  if (tooltipConfig.type === 'inline') {
    useEventListener(tooltipTrigger, 'focus', showTooltip)
    useEventListener(tooltipTrigger, 'blur', hideTooltip)

    useEventListener(tooltipTrigger, 'mouseenter', showTooltip)
    useEventListener(tooltipTrigger, 'mouseleave', hideTooltip)
  }

  onKeyStroke('Escape', (e) => {
    stopEvent(e)
    hideTooltip()
  })

  return {
    tooltipVisible,
    showTooltip,
    hideTooltip,
  }
}
