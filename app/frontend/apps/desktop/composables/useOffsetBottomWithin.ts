// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { unrefElement, useResizeObserver, type MaybeComputedElementRef } from '@vueuse/core'
import { readonly, ref } from 'vue'

/**
 * Distance between the top edge of `container` and the bottom edge of `element`, one of its
 * descendants. It is read from the rendered boxes, so a transform both share cancels out.
 */
export const useOffsetBottomWithin = (
  element: MaybeComputedElementRef,
  container: MaybeComputedElementRef,
) => {
  const offsetBottom = ref(0)

  const measure = () => {
    const elementNode = unrefElement(element)
    const containerNode = unrefElement(container)

    if (!elementNode || !containerNode) {
      offsetBottom.value = 0
      return
    }

    offsetBottom.value =
      elementNode.getBoundingClientRect().bottom - containerNode.getBoundingClientRect().top
  }

  useResizeObserver([element, container], measure)

  return readonly(offsetBottom)
}
