// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, onBeforeUnmount, shallowReadonly, shallowRef, toValue, watch } from 'vue'

import type { CoveringOverlay } from './types.ts'

// In the order the overlays were shown, not mounted, so the last one is on top: the image viewer
//   is mounted with the app, but lies over what it is shown on.
const overlays = shallowRef<CoveringOverlay[]>([])

const shownOverlays = shallowReadonly(overlays)

const isPageCovered = computed(() => overlays.value.length > 0)

/**
 * What the backdrops of the open dialogs and side panels cover, which is out of reach for the
 *   mouse and must be for the keyboard as well.
 */
export const useOverlayCoverage = () => ({ shownOverlays, isPageCovered })

export const useCoveringOverlay = (overlay: CoveringOverlay) => {
  const remove = () => {
    if (!overlays.value.includes(overlay)) return

    overlays.value = overlays.value.filter((candidate) => candidate !== overlay)
  }

  watch(
    () => toValue(overlay.isShown),
    (isShown) => {
      remove()

      if (isShown) overlays.value = [...overlays.value, overlay]
    },
    { immediate: true },
  )

  onBeforeUnmount(remove)
}
