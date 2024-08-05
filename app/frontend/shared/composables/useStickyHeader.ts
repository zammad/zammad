// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useScroll } from '@vueuse/core'
import { watch, ref, computed } from 'vue'

// eslint-disable-next-line import/no-restricted-paths
import type LayoutHeader from '#mobile/components/layout/LayoutHeader.vue'

import type { CSSProperties, WatchSource } from 'vue'

export const useStickyHeader = (
  dependencies: WatchSource[] = [],
  header = ref<InstanceType<typeof LayoutHeader> | HTMLElement>(),
) => {
  const { y, directions } = useScroll(window.document, {
    eventListenerOptions: { passive: true },
  })

  const stickyStyles = ref<{ header?: CSSProperties; body?: CSSProperties }>({})

  const headerElement = computed({
    get: () => {
      if (!header.value) return null
      return 'clientHeight' in header.value ? header.value : header.value?.$el
    },
    set: (value) => {
      header.value = value
    },
  })

  watch(
    [y, ...dependencies],
    () => {
      if (!header.value) {
        stickyStyles.value = {}
        return
      }
      const height = headerElement.value?.clientHeight || directions.top
      const show = y.value <= height
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
