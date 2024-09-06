// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  type MaybeComputedElementRef,
  type MaybeElement,
  onKeyStroke,
  useElementBounding,
  useWindowSize,
} from '@vueuse/core'
import { ref, type Ref, onBeforeUnmount } from 'vue'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

export const useResizeLine = (
  resizeCallback: (positionX: number) => void,
  resizeLineElementRef: MaybeComputedElementRef<MaybeElement>,
  keyStrokeCallback: (e: KeyboardEvent, adjustment: number) => void,
  options?: {
    calculateFromRight?: boolean
    /**
     * @default 'horizontal'
     * */
    orientation: 'horizontal' | 'vertical'
    offsetThreshold?: number
  },
) => {
  const isResizing = ref(false)

  const locale = useLocaleStore()
  const { height: screenHeight } = useWindowSize()

  const { width, height } = useElementBounding(
    resizeLineElementRef as MaybeComputedElementRef<MaybeElement>,
  )
  const { width: screenWidth } = useWindowSize()

  const handleVerticalResize = (event: MouseEvent | TouchEvent) => {
    // Position the cursor as close to the handle center as possible.
    let positionX = Math.round(width.value / 2)

    if (event instanceof MouseEvent) {
      positionX += event.pageX
    } else if (event.targetTouches[0]) {
      positionX += event.targetTouches[0].pageX
    }

    // In case of RTL locale, subtract the reported position from the current screen width.
    if (
      locale.localeData?.dir === EnumTextDirection.Rtl &&
      !options?.calculateFromRight // If the option is set, do not calculate from the right.
    )
      positionX = screenWidth.value - positionX

    // In case of LTR locale and resizer is used from right side of the window, subtract the reported position from the current screen width.
    if (
      locale.localeData?.dir === EnumTextDirection.Ltr &&
      options?.calculateFromRight
    )
      positionX = screenWidth.value - positionX

    resizeCallback(positionX)
  }

  const handleHorizontalResize = (event: MouseEvent | TouchEvent) => {
    // Position the cursor as close to the handle center as possible.
    let positionY = Math.round(height.value / 2)

    if (event instanceof MouseEvent) {
      positionY += event.pageY
    } else if (event.targetTouches[0]) {
      positionY += event.targetTouches[0].pageY
    }

    positionY = screenHeight.value - positionY - (options?.offsetThreshold ?? 0)

    resizeCallback(positionY)
  }

  const resize = (event: MouseEvent | TouchEvent) => {
    if (options?.orientation === 'vertical') return handleVerticalResize(event)

    handleHorizontalResize(event)
  }

  const endResizing = () => {
    // eslint-disable-next-line no-use-before-define
    removeListeners()
    isResizing.value = false
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

  const startResizing = (e: MouseEvent | TouchEvent) => {
    // Do not react on double click event.
    if (e.detail > 1) return

    e.preventDefault()

    isResizing.value = true

    addEventListeners()
  }

  onBeforeUnmount(() => {
    removeListeners()
  })

  // a11y keyboard navigation horizontal resize
  if (options?.orientation === 'vertical') {
    onKeyStroke(
      'ArrowLeft',
      (e: KeyboardEvent) => {
        if (options?.calculateFromRight) {
          keyStrokeCallback(e, locale.localeData?.dir === 'rtl' ? -5 : 5)
        } else {
          keyStrokeCallback(e, locale.localeData?.dir === 'rtl' ? 5 : -5)
        }
      },
      { target: resizeLineElementRef as Ref<EventTarget> },
    )

    onKeyStroke(
      'ArrowRight',
      (e: KeyboardEvent) => {
        if (options?.calculateFromRight) {
          keyStrokeCallback(e, locale.localeData?.dir === 'rtl' ? 5 : -5)
        } else {
          keyStrokeCallback(e, locale.localeData?.dir === 'rtl' ? -5 : 5)
        }
      },
      { target: resizeLineElementRef as Ref<EventTarget> },
    )
  } else {
    onKeyStroke(
      'ArrowUp',
      (e: KeyboardEvent) => {
        keyStrokeCallback(e, 5)
      },
      { target: resizeLineElementRef as Ref<EventTarget> },
    )

    onKeyStroke(
      'ArrowDown',
      (e: KeyboardEvent) => {
        keyStrokeCallback(e, -5)
      },
      { target: resizeLineElementRef as Ref<EventTarget> },
    )
  }

  return {
    isResizing,
    startResizing,
  }
}
