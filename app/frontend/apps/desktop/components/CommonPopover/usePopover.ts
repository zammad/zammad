// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, shallowRef } from 'vue'

import type { CommonPopoverInstance } from './types.ts'
import type { ShallowRef, Ref } from 'vue'

export const usePopover = (popoverRef?: Ref<CommonPopoverInstance | undefined>) => {
  const popover: ShallowRef<CommonPopoverInstance | undefined> = popoverRef || shallowRef()
  const popoverTarget: ShallowRef<HTMLDivElement | undefined> = shallowRef()

  const isOpen = computed(() => popover.value?.isOpen || false)

  const open = () => popover.value?.openPopover()

  const openDelayed = () => popover.value?.openPopoverDelayed()

  const close = () => popover.value?.closePopover()

  const toggle = (isInteractive = false) => popover.value?.togglePopover(isInteractive)

  return {
    popover,
    popoverTarget,
    open,
    openDelayed,
    close,
    toggle,
    isOpen,
  }
}
