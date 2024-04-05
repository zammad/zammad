// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref, onUnmounted } from 'vue'
import {
  type MaybeComputedElementRef,
  type MaybeElement,
  useElementBounding,
  useWindowSize,
} from '@vueuse/core'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

interface Emits {
  (event: 'resize-horizontal', arg: number): void
  (event: 'resize-horizontal-start'): void
  (event: 'resize-horizontal-end'): void
}

export const useResizeWidthHandle = (
  emit: Emits,
  handleRef: MaybeComputedElementRef<MaybeElement>,
) => {
  const isResizing = ref(false)

  const locale = useLocaleStore()
  const { width } = useElementBounding(handleRef)
  const { width: screenWidth } = useWindowSize()

  const resize = (event: MouseEvent | TouchEvent) => {
    // Position the cursor as close to the handle center as possible.
    let positionX = Math.round(width.value / 2)

    if (event instanceof MouseEvent) {
      positionX += event.pageX
    } else if (event.targetTouches[0]) {
      positionX += event.targetTouches[0].pageX
    }

    // In case of RTL locale, subtract the reported position from the current screen width.
    if (locale.localeData?.dir === EnumTextDirection.Rtl)
      positionX = screenWidth.value - positionX

    emit('resize-horizontal', positionX)
  }

  const endResizing = () => {
    // eslint-disable-next-line no-use-before-define
    removeListeners()
    isResizing.value = false
    emit('resize-horizontal-end')
  }

  const removeListeners = () => {
    document.removeEventListener('touchmove', resize)
    document.removeEventListener('touchend', endResizing)
    document.removeEventListener('mousemove', resize)
    document.removeEventListener('mouseup', endResizing)
  }
  const addEventListeners = () => {
    document.addEventListener('touchend', endResizing)
    document.addEventListener('touchmove', resize)
    document.addEventListener('mouseup', endResizing)
    document.addEventListener('mousemove', resize)
  }

  const startResizing = (e: MouseEvent) => {
    // Do not react on double click event.
    if (e.detail > 1) return

    e.preventDefault()

    isResizing.value = true
    emit('resize-horizontal-start')
    addEventListeners()
  }

  onUnmounted(() => {
    removeListeners()
  })

  return {
    isResizing,
    startResizing,
  }
}
