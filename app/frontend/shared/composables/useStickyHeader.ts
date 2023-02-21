// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useScroll } from '@vueuse/core'
import type { CSSProperties, WatchSource } from 'vue'
import { watch, ref } from 'vue'

export const useStickyHeader = (
  dependencies: WatchSource[] = [],
  headerElement = ref<HTMLElement>(),
) => {
  const { y, directions } = useScroll(window, {
    eventListenerOptions: { passive: true },
  })

  const stickyStyles = ref<{ header?: CSSProperties; body?: CSSProperties }>({})

  watch(
    [y, ...dependencies],
    () => {
      if (!headerElement.value) {
        stickyStyles.value = {}
        return
      }
      const height = headerElement.value.clientHeight
      const show = y.value <= height || directions.top
      stickyStyles.value = {
        header: {
          left: '0',
          right: '0',
          top: '0',
          zIndex: 9,
          position: 'fixed',
          transform: `translateY(${show ? '0px' : '-100%'})`,
          transition: 'transform 0.3s ease-in-out',
        },
        body: {
          marginTop: `${height}px`,
        },
      } as const
    },
    { flush: 'post' },
  )

  return {
    stickyStyles,
    headerElement,
  }
}
